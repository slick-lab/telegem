# lib/core/bot.rb - CORRECTED VERSION
module Telegem
  module Core
    class Bot
      attr_reader :token, :api, :handlers, :middleware, :logger, :scenes

      def initialize(token, **options)
        @token = token
        @api = API::Client.new(token, **options.slice(:endpoint, :logger))
        @handlers = {
          message: [],
          callback_query: [],
          inline_query: [],
          chat_member: [],
          poll: [],
          pre_checkout_query: [],
          shipping_query: []
        }
        @middleware = []
        @scenes = {}
        @logger = options[:logger] || Logger.new($stdout)
        @error_handler = nil
        @session_store = options[:session_store] || Session::MemoryStore.new
        @concurrency = options[:concurrency] || 10
        @polling_thread = nil
        @running = false
      end

      def command(name, **options, &block)
        pattern = /^\/#{Regexp.escape(name)}(?:@\w+)?(?:\s+(.+))?$/i

        on(:message, text: pattern) do |ctx|
          ctx.match = ctx.message.text.match(pattern)
          ctx.state[:command_args] = ctx.match[1] if ctx.match
          block.call(ctx)
        end
      end

      def hears(pattern, **options, &block)
        on(:message, text: pattern) do |ctx|
          ctx.match = ctx.message.text.match(pattern)
          block.call(ctx)
        end
      end

      def on(type, filters = {}, &block)
        @handlers[type] << { filters: filters, handler: block }
      end

      def use(middleware, *args, &block)
        @middleware << [middleware, args, block]
        self
      end

      def error(&block)
        @error_handler = block
      end

      def scene(id, &block)
        @scenes[id] = Scene.new(id, &block)
      end

      def start_polling(**options)
        return if @running
        
        @running = true
        @polling_thread = Thread.new do
          @logger.info "Starting polling..."
          offset = nil

          begin
            while @running
              updates = fetch_updates(offset, **options)
              
              # Process each update in its own thread
              updates.each do |update|
                Thread.new { process_update(update) }
              end

              offset = updates.last&.update_id.to_i + 1 if updates.any?
              sleep 0.1  # Small delay between polls
            end
          rescue => e
            handle_error(e)
            raise
          ensure
            @running = false
            @logger.info "Polling stopped"
          end
        end
        
        self
      end

      def webhook(app = nil, &block)
        require_relative '../../webhook/server'

        if block_given?
          Webhook::Server.new(self, &block)
        elsif app
          Webhook::Middleware.new(self, app)
        else
          Webhook::Server.new(self)
        end
      end

      def set_webhook(url, **options)
        future = @api.call('setWebhook', { url: url }.merge(options))
        future.value  # Wait for completion
      end

      def delete_webhook
        future = @api.call('deleteWebhook', {})
        future.value
      end

      def get_webhook_info
        future = @api.call('getWebhookInfo', {})
        future.value
      end

      def process(update_data)
        update = Types::Update.new(update_data)
        process_update(update)
      end

      def shutdown
        @logger.info "Shutting down..."
        
        @running = false
        @polling_thread&.join(5) if @polling_thread&.alive?
        @api.close
        
        @logger.info "Bot stopped"
      end

      def running?
        @running
      end

      private

      def fetch_updates(offset, timeout: 30, limit: 100, allowed_updates: nil)
        future = @api.get_updates(
          offset: offset,
          timeout: timeout,
          limit: limit,
          allowed_updates: allowed_updates
        )
        
        # Wait for the Future to complete
        updates_data = future.value
        
        # Convert raw data to Update objects
        updates_data.map { |data| Types::Update.new(data) }
      rescue API::APIError => e
        @logger.error "Failed to fetch updates: #{e.message}"
        []
      end

      def process_update(update)
        ctx = Context.new(update, self)

        begin
          run_middleware_chain(ctx) do |context|
            dispatch_to_handlers(context)
          end
        rescue => e
          handle_error(e, ctx)
        end
      end

      def run_middleware_chain(ctx, &final)
        chain = build_middleware_chain
        chain.call(ctx, &final)
      end

      def build_middleware_chain
        chain = Composer.new

        @middleware.each do |middleware_class, args, block|
          if middleware_class.respond_to?(:new)
            middleware = middleware_class.new(*args, &block)
            chain.use(middleware)
          else
            chain.use(middleware_class)
          end
        end

        unless @middleware.any? { |m, _, _| m.is_a?(Session::Middleware) }
          chain.use(Session::Middleware.new(@session_store))
        end

        chain
      end

      def dispatch_to_handlers(ctx)
        update_type = detect_update_type(ctx.update)
        handlers = @handlers[update_type] || []

        handlers.each do |handler|
          if matches_filters?(ctx, handler[:filters])
            handler[:handler].call(ctx)
            break  # First matching handler wins
          end
        end
      end

      def detect_update_type(update)
        return :message if update.message
        return :callback_query if update.callback_query
        return :inline_query if update.inline_query
        return :chat_member if update.chat_member
        return :poll if update.poll
        return :pre_checkout_query if update.pre_checkout_query
        return :shipping_query if update.shipping_query
        :unknown
      end

      def matches_filters?(ctx, filters)
        return true if filters.empty?

        filters.all? do |key, value|
          case key
          when :text
            matches_text_filter(ctx, value)
          when :chat_type
            matches_chat_type_filter(ctx, value)
          when :command
            matches_command_filter(ctx, value)
          else
            ctx.update.send(key) == value
          end
        end
      end

      def matches_text_filter(ctx, pattern)
        return false unless ctx.message&.text

        if pattern.is_a?(Regexp)
          ctx.message.text.match?(pattern)
        else
          ctx.message.text.include?(pattern.to_s)
        end
      end

      def matches_chat_type_filter(ctx, type)
        return false unless ctx.chat
        ctx.chat.type == type.to_s
      end

      def matches_command_filter(ctx, command_name)
        return false unless ctx.message&.command?
        ctx.message.command_name == command_name.to_s
      end

      def handle_error(error, ctx = nil)
        if @error_handler
          @error_handler.call(error, ctx)
        else
          @logger.error("Unhandled error: #{error.class}: #{error.message}")
          @logger.error(error.backtrace.join("\n")) if error.backtrace
        end
      end
    end
  end
end
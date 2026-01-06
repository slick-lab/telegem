require 'concurrent'
require 'logger'
require 'async'

module Telegem
  module Core
    class Bot
      attr_reader :token, :api, :handlers, :middleware, :logger, :scenes, 
                  :running, :session_store
      
      def initialize(token, **options)
        @token = token
        @api = API::Client.new(token, **options.slice(:logger, :timeout))
        
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

        @running = false 
        @offset = 0
      end
      
    def start_polling(**options)
      Async do
        poll_loop  # Now runs in Async context
      end
    end
      
      def shutdown
        return unless @running
        
        @logger.info "🛑 Shutting down bot..."
        @running = false
      end 
      def running?
        @running
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
      
      def webhook(app = nil, port: nil, host: '0.0.0.0', logger: nil, &block)
        require_relative '../webhook/server'
        
        if block_given?
          Webhook::Server.new(self, &block)
        elsif app
          Webhook::Middleware.new(self, app)
        else
          Webhook::Server.new(self, port: port, host: host, logger: logger)
        end
      end
      
      def set_webhook(url, **options, &callback)
        @api.call!('setWebhook', { url: url }.merge(options), &callback)
      end

      def delete_webhook(&callback)
        @api.call!('deleteWebhook', {}, &callback)
      end

      def get_webhook_info(&callback)
        @api.call!('getWebhookInfo', {}, &callback)
      end
      
      def process(update_data)
        update = Types::Update.new(update_data)
        process_update(update)
      end
      
      private
      
    def poll_loop
      fetch_updates do |result|
        if result && result['ok']
          handle_updates_response(result)
        end

        if @running
          # Schedule next poll in NEW async context
          Async { |task| 
            task.sleep(1)
            poll_loop 
          }
        end
      end
    end
     
      def fetch_updates(&completion_callback)
        params = {
          timeout: @polling_options[:timeout] || 30,
          limit: @polling_options[:limit] || 100
        }
        params[:offset] = @offset if @offset
        params[:allowed_updates] = @polling_options[:allowed_updates] if @polling_options[:allowed_updates]

        @logger.debug "Fetching updates with offset: #{@offset}"

        @api.call!('getUpdates', params) do |updates_array|
          # Success
          if updates_array && updates_array.is_a?(Array)
            result = { 'ok' => true, 'result' => updates_array }
            completion_callback.call(result) if completion_callback
          else
            completion_callback.call(nil) if completion_callback
          end
        end.on_error do |error|
          # Network/HTTP error
          @logger.error "Polling error: #{error.message}"
          completion_callback.call(nil, error) if completion_callback
        end
      end
         
            
      
      def handle_updates_response(api_response)
        if api_response['ok'] 
          updates = api_response['result'] || [] 
             updates.each do |data|
               Async do |task|
                update_object = Types::Update.new(data) 
                process_update(update_object)
               end 
             end 
           if updates.any? 
             @offset = updates.last['update_id'] + 1
             @logger.debug "Updated offset to; #{@offset}"
           end 
        end 
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
            break
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
          @logger.error("❌ Unhandled error: #{error.class}: #{error.message}")
          if ctx
            @logger.error("Context - User: #{ctx.from&.id}, Chat: #{ctx.chat&.id}")
          end
        end
      end
    end
  end
end 

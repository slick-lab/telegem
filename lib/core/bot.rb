require 'concurrent'
require 'logger'

module Telegem
  module Core
    class Bot
      attr_reader :token, :api, :handlers, :middleware, :logger, :scenes, 
                  :running, :polling_thread, :session_store
      
      def initialize(token, **options)
        @token = token
        @api = API::Client.new(token, **options.slice(:logger, :timeout))
        @api_mutex = Mutex.new  # ← LINE 1 ADDED HERE
        
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
        
        @thread_pool = Concurrent::FixedThreadPool.new(options[:max_threads] || 10)
        @update_queue = Queue.new
        @worker_threads = []
        
        @polling_thread = nil
        @running = false
        @offset = nil
        
        start_workers(options[:worker_count] || 5)
      end
      
      def start_polling(**options)
        return if @running
        
        @running = true
        @polling_options = {
          timeout: 30,
          limit: 100,
          allowed_updates: nil
        }.merge(options)
        
        @offset = nil
        
        @logger.info "🤖 Starting Telegem bot (polling mode)..."
        
        @polling_thread = Thread.new do
          Thread.current.abort_on_exception = false
          poll_loop
        end
        
        self
      end
      
      def shutdown
        return unless @running
        
        @logger.info "🛑 Shutting down bot..."
        @running = false
        
        if @polling_thread&.alive?
          @polling_thread.join(3)
        end
        
        stop_workers
        
        @api.close if @api.respond_to?(:close)
        
        @logger.info "✅ Bot shutdown complete"
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
      
      def set_webhook(url, **options)
        @api.call!('setWebhook', { url: url }.merge(options))
      end
      
      def delete_webhook
        @api.call!('deleteWebhook', {})
      end
      
      def get_webhook_info
        @api.call!('getWebhookInfo', {})
      end
      
      def process(update_data)
        update = Types::Update.new(update_data)
        process_update(update)
      end
      
      private
      
      def poll_loop
        @logger.debug "Entering polling loop"
        
        while @running
          begin
            result = fetch_updates
            
            if result && result.is_a?(Hash) && result['ok']
              handle_updates_response(result)
            elsif result
              @logger.warn "Unexpected API response format: #{result.class}"
            end
            
            sleep 0.1 unless @offset.nil?
            
          rescue => e
            handle_error(e)
            sleep 5
          end
        end
        
        @logger.debug "Exiting polling loop"
      end
      
      def fetch_updates
        params = {
          timeout: @polling_options[:timeout],
          limit: @polling_options[:limit]
        }
        params[:offset] = @offset if @offset
        params[:allowed_updates] = @polling_options[:allowed_updates] if @polling_options[:allowed_updates]
        
        @logger.debug("Fetching updates with offset: #{@offset}")
        
        # Simple direct call - no .wait
        updates = @api.call!('getUpdates', params)
        
        if updates && updates.is_a?(Array)
          @logger.debug("Got #{updates.length} updates")
          return { 'ok' => true, 'result' => updates }
        end
        
        nil
      end
      
      def handle_updates_response(api_response)
        updates = api_response['result'] || []
        
        if updates.any?
          @logger.debug "Processing #{updates.length} update(s)"
          
          updates.each do |update_data|
            @update_queue << [update_data, nil]
          end
          
          @offset = updates.last['update_id'] + 1
          @logger.debug "Updated offset to #{@offset}"
        end
      end
      
      def start_workers(count)
        count.times do |i|
          @worker_threads << Thread.new do
            Thread.current.abort_on_exception = false
            worker_loop(i)
          end
        end
        @logger.debug "Started #{count} worker threads"
      end
      
      def stop_workers
        @logger.debug "Stopping worker threads"
        
        @worker_threads.size.times { @update_queue << :shutdown }
        
        @worker_threads.each do |thread|
          thread.join(2) if thread.alive?
        end
        
        @worker_threads.clear
      end
      
      def worker_loop(id)
        @logger.debug "Worker #{id} started"
        
        while @running
          begin
            task = @update_queue.pop
            
            break if task == :shutdown
            
            update_data, callback = task
            process_update(Types::Update.new(update_data))
            
            callback&.call if callback.respond_to?(:call)
            
          rescue => e
            @logger.error "Worker #{id} error: #{e.message}"
          end
        end
        
        @logger.debug "Worker #{id} stopped"
      end
      
      def process_update(update)
        @api_mutex.synchronize do  # ← LINE 2 ADDED HERE
          ctx = Context.new(update, self)
          
          begin
            run_middleware_chain(ctx) do |context|
              dispatch_to_handlers(context)
            end
          rescue => e
            handle_error(e, ctx)
          end
        end  # ← This 'end' matches the 'do' above
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
# lib/core/bot.rb - Telegem v2.0.0 (Stable)
require 'concurrent'
require 'logger'

module Telegem
  module Core
    class Bot
      # Public accessors for bot state and components
      attr_reader :token, :api, :handlers, :middleware, :logger, :scenes, 
                  :running, :polling_thread, :session_store
      
      def initialize(token, **options)
        @token = token
        @api = API::Client.new(token, **options.slice(:logger, :timeout))
        
        # Initialize handler registries for different update types
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
        
        # Thread pool and worker management
        @thread_pool = Concurrent::FixedThreadPool.new(options[:max_threads] || 10)
        @update_queue = Queue.new
        @worker_threads = []
        
        # Polling state
        @polling_thread = nil
        @running = false
        @offset = nil  # Last processed update ID
        
        # Start worker threads for processing updates
        start_workers(options[:worker_count] || 5)
      end
      
      # ========================
      # POLLING LIFECYCLE METHODS
      # ========================
      
      def start_polling(**options)
        return if @running
        
        @running = true
        @polling_options = {
          timeout: 30,
          limit: 100,
          allowed_updates: nil
        }.merge(options)
        
        @offset = nil  # Reset offset when starting
        
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
        
        # Gracefully stop polling thread
        if @polling_thread&.alive?
          @polling_thread.join(3)
        end
        
        # Stop worker threads
        stop_workers
        
        # Close API connections
        @api.close if @api.respond_to?(:close)
        
        @logger.info "✅ Bot shutdown complete"
      end
      
      def running?
        @running
      end
      
      # ========================
      # COMMAND & EVENT HANDLERS
      # ========================
      
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
      
      # ========================
      # WEBHOOK METHODS
      # ========================
      
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
      
      # ========================
      # UPDATE PROCESSING
      # ========================
      
      def process(update_data)
        update = Types::Update.new(update_data)
        process_update(update)
      end
      
      # ========================
      # PRIVATE METHODS
      # ========================
      
      private
      
      # ----- POLLING LOGIC -----
      
      def poll_loop
        @logger.debug "Entering polling loop"
        
        while @running
          begin
            # Use synchronous call to avoid HTTPX version conflicts
            result = fetch_updates
            
            if result && result.is_a?(Hash) && result['ok']
              handle_updates_response(result)
            elsif result
              @logger.warn "Unexpected API response format"
            end
            
            # Small delay between polls unless we just processed updates
            sleep 0.1 unless @offset.nil?
            
          rescue => e
            handle_error(e)
            sleep 5  # Wait before retrying after error
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
        
        # Use call! for synchronous operation (more reliable)
        @api.call!('getUpdates', params)
      end
      
      def handle_updates_response(api_response)
        updates = api_response['result'] || []
        
        if updates.any?
          @logger.debug "Processing #{updates.length} update(s)"
          
          updates.each do |update_data|
            # Queue for processing by worker threads
            @update_queue << [update_data, nil]
          end
          
          # Update offset for next request
          @offset = updates.last['update_id'] + 1
          @logger.debug "Updated offset to #{@offset}"
        end
      end
      
      # ----- WORKER THREAD MANAGEMENT -----
      
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
        
        # Send shutdown signals to all workers
        @worker_threads.size.times { @update_queue << :shutdown }
        
        # Wait for threads to finish
        @worker_threads.each do |thread|
          thread.join(2) if thread.alive?
        end
        
        @worker_threads.clear
      end
      
      def worker_loop(id)
        @logger.debug "Worker #{id} started"
        
        while @running
          begin
            # Wait for a task from the queue
            task = @update_queue.pop
            
            # Check for shutdown signal
            break if task == :shutdown
            
            update_data, callback = task
            process_update(Types::Update.new(update_data))
            
            # Execute callback if provided
            callback&.call if callback.respond_to?(:call)
            
          rescue => e
            @logger.error "Worker #{id} error: #{e.message}"
          end
        end
        
        @logger.debug "Worker #{id} stopped"
      end
      
      # ----- UPDATE PROCESSING PIPELINE -----
      
      def process_update(update)
        ctx = Context.new(update, self)
        
        begin
          # Run through middleware chain, then dispatch to handlers
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
        
        # Add user-defined middleware
        @middleware.each do |middleware_class, args, block|
          if middleware_class.respond_to?(:new)
            middleware = middleware_class.new(*args, &block)
            chain.use(middleware)
          else
            chain.use(middleware_class)
          end
        end
        
        # Add session middleware if not already present
        unless @middleware.any? { |m, _, _| m.is_a?(Session::Middleware) }
          chain.use(Session::Middleware.new(@session_store))
        end
        
        chain
      end
      
      def dispatch_to_handlers(ctx)
        update_type = detect_update_type(ctx.update)
        handlers = @handlers[update_type] || []
        
        # Find and execute the first matching handler
        handlers.each do |handler|
          if matches_filters?(ctx, handler[:filters])
            handler[:handler].call(ctx)
            break  # First matching handler wins
          end
        end
      end
      
      # ----- FILTER MATCHING LOGIC -----
      
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
      
      # ----- ERROR HANDLING -----
      
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
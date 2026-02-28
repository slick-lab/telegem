#frozen_string_literal: true
require 'json'
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
          shipping_query: [],
          poll_answer: [],
          chat_join_request: [],
          chat_boost: [],
          removed_chat_boost: [],
          message_reaction: [],
          message_reaction_count: []
        }
        
        @middleware = []
        @scenes = {}
        @logger = options[:logger] || Logger.new($stdout)
        @error_handler = nil
        @session_store = options[:session_store] || Session::MemoryStore.new

        @running = false 
        @offset = 0
        @polling_options = options.slice(:timeout, :limit, :allowed_updates) || {}
      end
      
      def start_polling(**options)
        @running = true
        @polling_options = options
        Async do
          poll_loop
        end
      end
      
      def shutdown
        return unless @running
        
        @logger.info "🛑 Shutting down bot..."
        @running = false
        sleep 0.1
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
      
      def contact(**options, &block) 
        on(:message, contact: true) do |ctx| 
          block.call(ctx)
        end 
      end 
      
      def poll_answer(&block) 
        on(:poll_answer) do |ctx| 
          block.call(ctx)
        end
      end 
      
      def pre_checkout_query(&block) 
        on(:pre_checkout_query) do |ctx| 
          block.call(ctx) 
        end 
      end 
      
      def shipping_query(&block) 
        on(:shipping_query) do |ctx| 
          block.call(ctx) 
        end 
      end 
      
      def chat_join_request(&block)
        on(:chat_join_request) do |ctx|
          block.call(ctx)
        end
      end

      def chat_boost(&block)
        on(:chat_boost) do |ctx|
          block.call(ctx)
        end
      end

      def removed_chat_boost(&block)
        on(:removed_chat_boost) do |ctx|
          block.call(ctx)
        end
      end

      def message_reaction(&block)
        on(:message_reaction) do |ctx|
          block.call(ctx)
        end
      end

      def message_reaction_count(&block)
        on(:message_reaction_count) do |ctx|
          block.call(ctx)
        end
      end
      
      def web_app_data(&block) 
        on(:message, web_app_data: true) do |ctx|
          block.call(ctx) 
        end 
      end 
      
      def set_my_profile_photo(photo, **options)
        @api.call('setMyProfilePhoto', {
          photo: photo
      }.merge(options))
    end 

    def remove_my_profile_photo
      @api.call('removeMyProfilePhoto', {})
    end 

    def get_user_profile_audios(user_id, **options)
      result = @api.call('getUserProfileAudios', {
        user_id: user_id
    }.merge(options))
    return nil unless result && result['audios']
    Types::UserProfileAudios.new(result)
    end 

    def create_forum_topic(chat_id, name, **options)
      @api.call('createForumTopic', {
        chat_id: chat_id,
        name: name
    }.merge(options))
  end 
      def location(&block)
        on(:message, location: true) do |ctx|
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
        if callback
          @api.call!('setWebhook', { url: url }.merge(options), &callback)
        else
          @api.call('setWebhook', { url: url }.merge(options))
        end
      end

      def delete_webhook(&callback)
        if callback
          @api.call!('deleteWebhook', {}, &callback)
        else
          @api.call('deleteWebhook', {})
        end
      end

      def get_webhook_info(&callback)
        if callback
          @api.call!('getWebhookInfo', {}, &callback)
        else
          @api.call('getWebhookInfo', {})
        end
      end
      
      def process(update_data)
        update = Types::Update.new(update_data)
        process_update(update)
      end

      
      
      private
      
      def poll_loop
        while @running
          begin
            updates = @api.get_updates(
              offset: @offset,
              timeout: @polling_options[:timeout] || 30,
              limit: @polling_options[:limit] || 100,
              allowed_updates: @polling_options[:allowed_updates]
            )
            
            if updates && updates.any?
              updates.each do |update_data|
                  update = Types::Update.new(update_data)
                  process_update(update)
                end
              @offset = updates.last['update_id'] + 1
              @logger.debug("Updated offset to: #{@offset}")
            end
          rescue => e
            @logger.error("Poll loop error: #{e.message}")
            sleep 1
          end
        end
      end
      
      def process_update(update)
        if update.message&.text && @logger
          user = update.message.from
          cmd = update.message.text.split.first
          @logger.info("#{cmd} - #{user.username}")
        end

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
        
        unless @middleware.any? { |m, _, _| m.to_s =~ /Scene/ }
          begin
            require_relative '../session/scene_middleware'
            chain.use(Telegem::Scene::Middleware.new)
          rescue LoadError => e
            @logger.debug("Scene middleware not available: #{e.message}") if @logger
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
        return :poll_answer if update.poll_answer
        return :chat_join_request if update.chat_join_request
        return :chat_boost if update.chat_boost
        return :removed_chat_boost if update.removed_chat_boost 
        return :message_reaction if update.message_reaction
        return :message_reaction_count if update.message_reaction_count 
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
          when :location 
            ctx.message&.location != nil 
          when :contact 
            ctx.message&.contact != nil 
          when :web_app_data 
            ctx.message&.web_app_data != nil
          else 
            if ctx.update.respond_to?(key)
              ctx.update.send(key) == value
            else 
              false 
            end 
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
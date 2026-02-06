
module Telegem
  class RateLimit
    def initialize(**options)
      @options = {
        global: { max: 30, per: 1 },    # 30 reqs/second globally
        user: { max: 5, per: 10 },      # 5 reqs/10 seconds per user
        chat: { max: 20, per: 60 }      # 20 reqs/minute per chat
      }.merge(options)
      
      @counters = {
        global: Telegem::Session::MemoryStore.new,
        user: Telegem::Session::MemoryStore.new,
        chat: Telegem::Session::MemoryStore.new
      }
    end
    
    def call(ctx, next_middleware)
      return next_middleware.call(ctx) unless should_rate_limit?(ctx)
      
      if limit_exceeded?(ctx)
        ctx.logger&.warn("Rate limit exceeded for #{ctx.from&.id}")
        return rate_limit_response(ctx)
      end
      
      increment_counters(ctx)
      next_middleware.call(ctx)
    end
    
    private
    
    def should_rate_limit?(ctx)
      
      return false if ctx.update.poll?
      return false if ctx.update.chat_member?
      return true
    end
    
    def limit_exceeded?(ctx)
      global_limit?(ctx) || user_limit?(ctx) || chat_limit?(ctx)
    end
    
    def global_limit?(ctx)
      check_limit(:global, "global", ctx)
    end
    
    def user_limit?(ctx)
      return false unless ctx.from&.id
      check_limit(:user, "user:#{ctx.from.id}", ctx)
    end
    
    def chat_limit?(ctx)
      return false unless ctx.chat&.id
      check_limit(:chat, "chat:#{ctx.chat.id}", ctx)
    end
    
    def check_limit(type, key, ctx)
      limit = @options[type]
      return false unless limit
      
      counter = @counters[type].get(key) || 0
      counter >= limit[:max]
    end
    
    def increment_counters(ctx)
      now = Time.now.to_i
      
      
      if @options[:global]
        key = "global"
        cleanup_counter(:global, key, now)
        @counters[:global].increment(key, 1, ttl: @options[:global][:per])
      end
      
      
      if @options[:user] && ctx.from&.id
        key = "user:#{ctx.from.id}"
        cleanup_counter(:user, key, now)
        @counters[:user].increment(key, 1, ttl: @options[:user][:per])
      end
      
      
      if @options[:chat] && ctx.chat&.id
        key = "chat:#{ctx.chat.id}"
        cleanup_counter(:chat, key, now)
        @counters[:chat].increment(key, 1, ttl: @options[:chat][:per])
      end
    end
    
    def cleanup_counter(type, key, now)
      expires = @counters[type].get_ttl(key) || now
      @counters[type].delete(key) if now > expires 
    end
    
    def rate_limit_response(ctx)
      
      ctx.reply("⏳ Please wait a moment before sending another request.") rescue nil
      nil
    end
  end 
end
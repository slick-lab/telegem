# lib/session/middleware.rb - UPDATED
module Telegem
  module Session
    class Middleware
      def initialize(store = nil)
        @store = store || MemoryStore.new
      end

      def call(ctx, next_middleware)
        user_id = get_user_id(ctx)
        return next_middleware.call(ctx) unless user_id

        # Load session
        ctx.session = @store.get(user_id) || {}
        
        # Run the chain
        result = next_middleware.call(ctx)
        
        # Save session (regardless of result)
        @store.set(user_id, ctx.session)
        
        # Return whatever the chain returned
        result
      rescue => e
        # Save session even on error
        @store.set(user_id, ctx.session) if user_id && ctx.session
        raise e
      end
      
      private
      
      def get_user_id(ctx)
        ctx.from&.id
      end
    end
  end
end
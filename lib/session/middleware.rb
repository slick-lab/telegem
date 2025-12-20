module Telegem
  module Session
    class Middleware
      def initialize(store = nil)
        @store = store || MemoryStore.new
      end

      def call(ctx, next_middleware)
        user_id = get_user_id(ctx)
        return next_middleware.call(ctx) unless user_id

        ctx.session = @store.get(user_id) || {}

        begin
          result = next_middleware.call(ctx)
          # Handle async result
          result.is_a?(Async::Task) ? result : Async::Task.new(result)
        ensure
          @store.set(user_id, ctx.session)
        end
      end
      private

      def get_user_id(ctx)
        return nil unless ctx.from

        ctx.from.id
      end
    end

    class MemoryStore
      def initialize
        @store = {}
      end

      def get(key)
        @store[key]
      end

      def set(key, value)
        @store[key] = value
      end

      def delete(key)
        @store.delete(key)
      end

      def clear
        @store.clear
      end
    end
  end
end

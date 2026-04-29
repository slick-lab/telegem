# lib/core/composer.rb - HTTPX VERSION (NO ASYNC GEM)
module Telegem
  module Core
    class Composer
      def initialize
        @middleware = []
      end

      def use(middleware)
        @middleware << middleware
        self
      end

      def call(ctx, &final)
        return final.call(ctx) if @middleware.empty?

        # Build the middleware chain
        chain = final
        
        # Reverse the middleware so last added runs last in chain
        @middleware.reverse_each do |middleware|
          chain = create_middleware_wrapper(middleware, chain)
        end
        
        # Execute the chain
        chain.call(ctx)
      end

      def empty?
        @middleware.empty?
      end

      private

      def create_middleware_wrapper(middleware, next_middleware)
        ->(context) do
          middleware_instance = instantiate_middleware(middleware)
          
          if middleware_instance.respond_to?(:call)
            # Call the middleware with next in chain
            middleware_instance.call(context, next_middleware)
          else
            raise "Invalid middleware: #{middleware.inspect} does not respond to :call"
          end
        end
      end

      def instantiate_middleware(middleware)
        case middleware
        when Class
          middleware.new
        when Proc, Method
          middleware
        else
          # Assume it's already a middleware instance
          middleware
        end
      end
    end
  end
end

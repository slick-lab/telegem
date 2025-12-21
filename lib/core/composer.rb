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

        # Build async-aware chain
        chain = final

        @middleware.reverse_each do |middleware|
          chain = ->(context) do
            if middleware.respond_to?(:call)
              result = middleware.call(context, chain)
              result.is_a?(Async::Task) ? result : Async::Task.new(result)
            elsif middleware.is_a?(Class)
              instance = middleware.new
              result = instance.call(context, chain)
              result.is_a?(Async::Task) ? result : Async::Task.new(result)
            else
              raise "Invalid middleware: #{middleware.class}"
            end
          end
        end

        # Execute the chain
        chain.call(ctx)
      end

      def empty?
        @middleware.empty?
      end
    end 
  end 
end 
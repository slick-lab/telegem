# lib/core/scene.rb - HTTPX VERSION (NO ASYNC GEM)
module Telegem
  module Core
    class Scene
      attr_reader :id, :steps, :enter_callbacks, :leave_callbacks

      def initialize(id, default_step: :start, &block)
        @id = id
        @steps = {}
        @enter_callbacks = []
        @leave_callbacks = []
        @default_step = default_step
        instance_eval(&block) if block_given?
      end

      def step(name, &action)
        @steps[name.to_sym] = action
        self
      end

      def on_enter(&callback)
        @enter_callbacks << callback
        self
      end

      def on_leave(&callback)
        @leave_callbacks << callback
        self
      end

      def enter(ctx, step_name = nil)
        step_name ||= @default_step
        
        # Store scene state in context
        ctx.scene = { id: @id, step: step_name.to_sym }
        
        # Run enter callbacks
        @enter_callbacks.each { |cb| cb.call(ctx) }
        
        # Enter the first step
        process_step(ctx, step_name)
      end

      def leave(ctx)
        # Run leave callbacks
        @leave_callbacks.each { |cb| cb.call(ctx) }
        
        # Clear scene from context
        ctx.scene = nil
        nil
      end

      def process_step(ctx, step_name)
        step = @steps[step_name.to_sym]
        
        unless step
          ctx.logger.error("Unknown step #{step_name} in scene #{@id}")
          return nil
        end
        
        # Execute the step
        result = step.call(ctx)
        
        # Update step in context (unless step changed it)
        if ctx.scene && ctx.scene[:id] == @id
          ctx.scene[:step] = step_name.to_sym
        end
        
        result
      rescue => e
        ctx.logger.error("Error processing step #{step_name} in scene #{@id}: #{e.message}")
        ctx.logger.error(e.backtrace.join("\n")) if e.backtrace
        nil
      end

      def current_step(ctx)
        return nil unless ctx.scene && ctx.scene[:id] == @id
        ctx.scene[:step]
      end

      def reset(ctx)
        ctx.scene = { id: @id, step: @default_step }
        self
      end

      def to_s
        "#<Scene #{@id}>"
      end
    end
  end
end
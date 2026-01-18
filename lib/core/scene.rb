
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
        @timeout = 300  # 5 minutes default timeout
        
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
      
      def timeout(seconds)
        @timeout = seconds
        self
      end
      
  
      def enter(ctx, step_name = nil, **initial_data)
        step_name ||= @default_step
        
      
        ctx.session[:telegem_scene] = {
          id: @id.to_s,
          step: step_name.to_s,
          data: initial_data,
          entered_at: Time.now.to_i,
          timeout: @timeout,
          waiting_for_response: false,
          last_question: nil
        }
        
        ctx.instance_variable_set(:@current_scene, self)

        @enter_callbacks.each { |cb| cb.call(ctx) }
        

        execute_step(ctx, step_name)
      end
      

      def process(ctx)
        scene_data = ctx.session[:telegem_scene]
        return unless scene_data
        

        if Time.now.to_i - scene_data[:entered_at] > scene_data[:timeout]
          leave(ctx, :timeout)
          return
        end
        
        if scene_data[:waiting_for_response] && ctx.message&.text
          process_response(ctx, scene_data)
        else

          execute_step(ctx, scene_data[:step])
        end
      end

      def leave(ctx, reason = :manual)
        scene_data = ctx.session.delete(:telegem_scene)
        ctx.instance_variable_set(:@current_scene, nil)
        

        @leave_callbacks.each { |cb| cb.call(ctx, reason, scene_data[:data]) }
        
        scene_data[:data]
      end
      

      def current_step(ctx)
        scene_data = ctx.session[:telegem_scene]
        scene_data[:step] if scene_data
      end
      
      
      def scene_data(ctx)
        ctx.session[:telegem_scene]&.[](:data) || {}
      end
      
      private

      def execute_step(ctx, step_name)
        action = @steps[step_name.to_sym]
        return leave(ctx, :invalid_step) unless action

        scene_data = ctx.session[:telegem_scene]
        scene_data[:step] = step_name.to_s
        scene_data[:waiting_for_response] = false
        scene_data[:last_question] = nil
        
       
        result = action.call(ctx, scene_data[:data])
        

        if result.is_a?(Symbol) || result.is_a?(String)
          next_step(ctx, result)
        end
        
        result
      end
      
      
      def process_response(ctx, scene_data)

        current_step_name = scene_data[:step]
        scene_data[:data][current_step_name] = ctx.message.text
        
  
        scene_data[:waiting_for_response] = false
        
        next_step(ctx)
      end
      

      def next_step(ctx, specific_step = nil)
        scene_data = ctx.session[:telegem_scene]
        return unless scene_data
        
        current_step = scene_data[:step].to_sym
        step_names = @steps.keys
        
        if specific_step
          next_step_name = specific_step.to_sym
        else
          current_index = step_names.index(current_step)
          next_step_name = step_names[current_index + 1] if current_index
        end
        
        if next_step_name
          execute_step(ctx, next_step_name)
        else
          leave(ctx, :completed)
        end
      end
    end
  end
end
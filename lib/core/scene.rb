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
                Async do
                  step_name ||= @default_step
                  ctx.scene = { id: @id, step: step_name.to_sym }
                  @enter_callbacks.each { |cb| await(cb.call(ctx)) }
                  await process_step(ctx, step_name)
                rescue => e
                  ctx.logger.error("Error entering scene #{@id}: #{e.message}") 
                  raise 
                end
              end

              def leave(ctx) 
                Async do 
                  @leave_callbacks.each { |cb| await(cb.call(ctx)) }
                  ctx.scene = nil 
                rescue => e
                  ctx.logger.error("Error leaving scene #{@id}: #{e.message}")
                  raise 
                end
              end

              def process_step(ctx, step_name)
                Async do 
                  step = @steps[step_name.to_sym] 
                  raise "Unknown step #{step_name} in scene #{@id}" unless step 

                  result = step.call(ctx)
                  result = await(result) if result.is_a?(Async::Task)
                  ctx.scene[:step] = step_name.to_sym
                  result
                rescue => e
                  ctx.logger.error("Error processing step #{step_name} in scene #{@id}: #{e.message}")
                  raise 
                end
              end

              def current_step(ctx)
                ctx.scene[:step] if ctx.scene && ctx.scene[:id] == @id 
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
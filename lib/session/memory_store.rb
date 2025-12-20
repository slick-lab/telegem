      module Telegem
        module Session
          class MemoryStore
            def initialize
              @store = {}
              @mutex = Mutex.new
            end

            def get(key)
              @mutex.synchronize do
                @store[key.to_s]
              end
            end

            def set(key, value)
              @mutex.synchronize do
                @store[key.to_s] = value
              end
            end

            def delete(key)
              @mutex.synchronize do
                @store.delete(key.to_s)
              end
            end

            def clear
              @mutex.synchronize do
                @store.clear
              end
            end

            def keys
              @mutex.synchronize do
                @store.keys
              end
            end

            def size
              @mutex.synchronize do
                @store.size
              end
            end

            def empty?
              @mutex.synchronize do
                @store.empty?
              end
            end 

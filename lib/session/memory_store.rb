# lib/core/memory_store.rb - Generic in-memory store for caching/rate limiting
module Telegem
  module Core
    class MemoryStore
      def initialize(default_ttl: 300) # 5 minutes default
        @store = {}
        @ttls = {}
        @mutex = Mutex.new
        @default_ttl = default_ttl
      end

      # Store with optional TTL (Time To Live in seconds)
      def set(key, value, ttl: nil)
        @mutex.synchronize do
          @store[key.to_s] = value
          @ttls[key.to_s] = Time.now + (ttl || @default_ttl)
        end
      end

      # Get value if not expired
      def get(key)
        @mutex.synchronize do
          key_s = key.to_s
          return nil unless @store.key?(key_s)
          
          # Check if expired
          if @ttls[key_s] && Time.now > @ttls[key_s]
            delete(key_s)
            return nil
          end
          
          @store[key_s]
        end
      end

      # Check if key exists and not expired
      def exist?(key)
        @mutex.synchronize do
          key_s = key.to_s
          return false unless @store.key?(key_s)
          
          # Check if expired
          if @ttls[key_s] && Time.now > @ttls[key_s]
            delete(key_s)
            return false
          end
          
          true
        end
      end

      # Delete key
      def delete(key)
        @mutex.synchronize do
          key_s = key.to_s
          @store.delete(key_s)
          @ttls.delete(key_s)
        end
      end

      # Increment counter (for rate limiting)
      def increment(key, amount = 1, ttl: nil)
        @mutex.synchronize do
          key_s = key.to_s
          current = get(key_s) || 0
          new_value = current + amount
          set(key_s, new_value, ttl: ttl)
          new_value
        end
      end

      # Decrement counter
      def decrement(key, amount = 1)
        increment(key, -amount)
      end

      # Clear expired entries
      def cleanup
        @mutex.synchronize do
          now = Time.now
          @ttls.each do |key, expires|
            if now > expires
              @store.delete(key)
              @ttls.delete(key)
            end
          end
        end
      end

      # Clear everything
      def clear
        @mutex.synchronize do
          @store.clear
          @ttls.clear
        end
      end

      # Get all keys (non-expired)
      def keys
        @mutex.synchronize do
          cleanup # Remove expired first
          @store.keys
        end
      end

      # Get size (non-expired entries)
      def size
        keys.size
      end

      def empty?
        size == 0
      end

      # Get TTL remaining in seconds
      def ttl(key)
        @mutex.synchronize do
          key_s = key.to_s
          return -1 unless @ttls[key_s]
          
          remaining = @ttls[key_s] - Time.now
          remaining > 0 ? remaining.ceil : -1
        end
      end

      # Set TTL for existing key
      def expire(key, ttl)
        @mutex.synchronize do
          key_s = key.to_s
          return false unless @store.key?(key_s)
          
          @ttls[key_s] = Time.now + ttl
          true
        end
      end
    end  # class MemoryStore
  end    # module Core
end      # module Telegem
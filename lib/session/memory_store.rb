# lib/session/memory_store.rb - PRODUCTION READY
module Telegem
  module Session
    class MemoryStore
      def initialize
        @store = {}
        @ttls = {}
        @mutex = Mutex.new
        @default_ttl = 300  # 5 minutes
        @cleanup_interval = 60  # Clean expired every minute
        @last_cleanup = Time.now
      end

      # Store with optional TTL
      def set(key, value, ttl: nil)
        @mutex.synchronize do
          auto_cleanup
          key_s = key.to_s
          @store[key_s] = value
          @ttls[key_s] = Time.now + (ttl || @default_ttl)
          value
        end
      end

      # Get value if not expired
      def get(key)
        @mutex.synchronize do
          key_s = key.to_s
          return nil unless @store.key?(key_s)
          
          # Auto-clean if expired
          if expired?(key_s)
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
          !expired?(key_s)
        end
      end

      # Delete key
      def delete(key)
        @mutex.synchronize do
          key_s = key.to_s
          @store.delete(key_s)
          @ttls.delete(key_s)
          true
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

      # Clear expired entries (auto-called)
      def cleanup
        @mutex.synchronize do
          now = Time.now
          @ttls.each do |key, expires|
            if now > expires
              @store.delete(key)
              @ttls.delete(key)
            end
          end
          @last_cleanup = now
        end
      end

      # Clear everything
      def clear
        @mutex.synchronize do
          @store.clear
          @ttls.clear
          @last_cleanup = Time.now
        end
      end

      # Get all keys (non-expired)
      def keys
        @mutex.synchronize do
          auto_cleanup
          @store.keys.select { |k| !expired?(k) }
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

      # Redis-like scan for pattern matching
      def scan(pattern = "*", count: 10)
        @mutex.synchronize do
          auto_cleanup
          regex = pattern_to_regex(pattern)
          matching_keys = @store.keys.select { |k| k.match?(regex) && !expired?(k) }
          matching_keys.first(count)
        end
      end

      private

      def expired?(key)
        @ttls[key] && Time.now > @ttls[key]
      end

      def auto_cleanup
        if Time.now - @last_cleanup > @cleanup_interval
          cleanup
        end
      end

      def pattern_to_regex(pattern)
        # Convert Redis-style pattern to Ruby regex
        regex_str = pattern.gsub('*', '.*').gsub('?', '.')
        Regexp.new("^#{regex_str}$")
      end
    end
  end
end
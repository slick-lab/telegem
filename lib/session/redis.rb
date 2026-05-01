# lib/session/redis_store.rb
require 'json'
require 'time'

module Telegem
  module Session
    class RedisStore
      def initialize(redis_url: nil, default_ttl: 300, **options)
        @default_ttl = default_ttl
        
        # Load redis gem only when needed
        begin
          require 'redis'
        rescue LoadError
          raise "Redis store requires 'redis' gem. Add 'gem \"redis\"' to your Gemfile."
        end
        
        @redis = if redis_url
          Redis.new(url: redis_url, **options)
        else
          Redis.new(**options)
        end
      end
      
      def set(key, value, ttl: nil)
        key_s = key.to_s
        serialized = JSON.generate(value)
        ttl_sec = ttl || @default_ttl
        
        @redis.setex(key_s, ttl_sec, serialized)
        value
      end
      
      def get(key)
        key_s = key.to_s
        data = @redis.get(key_s)
        return nil unless data
        
        JSON.parse(data)
      rescue JSON::ParserError
        nil
      end
      
      def delete(key)
        key_s = key.to_s
        @redis.del(key_s) > 0
      end
      
      def increment(key, amount = 1, ttl: nil)
        key_s = key.to_s
        ttl_sec = ttl || @default_ttl
        
        # Atomic increment using Redis
        new_val = @redis.incrby(key_s, amount)
        
        # Set expiry if this is a new key or if TTL changed
        if ttl_sec
          @redis.expire(key_s, tttl_sec)
        end
        
        new_val
      end
      
      def clear_all
        # Be careful with this in production
        @redis.flushdb
      end
      
      def close
        @redis.close
      end
      
      private
      
      def with_retry(max_retries = 3, &block)
        retries = 0
        begin
          block.call
        rescue Redis::BaseError => e
          retries += 1
          if retries <= max_retries
            sleep 0.1 * retries
            retry
          else
            raise
          end
        end
      end
    end
  end
end

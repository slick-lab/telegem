# lib/session/memory_store.rb
require 'json'
require 'time'
require 'fileutils'

module Telegem
  module Session
    class MemoryStore
      def initialize(
        default_ttl: 300,
        cleanup_interval: 300,
        backup_path: nil,
        backup_interval: 60
      )
        @store = {}
        @ttls = {}
        @default_ttl = default_ttl
        @cleanup_interval = cleanup_interval
        @backup_path = backup_path
        @backup_interval = backup_interval

        @last_cleanup = Time.now
        @last_backup = Time.now

        restore! if @backup_path && File.exist?(@backup_path)
      end

      def set(key, value, ttl: nil)
        auto_cleanup
        key_s = key.to_s

        @store[key_s] = value
        @ttls[key_s] = Time.now + (ttl || @default_ttl)

        auto_backup
        value
      end

      def get(key)
        key_s = key.to_s
        return nil unless @store.key?(key_s)

        if expired?(key_s)
          delete(key_s)
          return nil
        end

        @store[key_s]
      end

      def delete(key)
        key_s = key.to_s
        @store.delete(key_s)
        @ttls.delete(key_s)
        true
      end

      def increment(key, amount = 1, ttl: nil)
        current = get(key) || 0
        # Ensure we are working with numbers 
        val = current.to_i rescue 0
        new_val = val + amount
        set(key, new_val, ttl: ttl)
        new_val
      end

      # --- Persistence Logic (The "Telecr" Way) ---

      def backup!
        return unless @backup_path
        
        # 1. Prepare data
        data = {
          "store" => @store,
          "ttls"  => @ttls.transform_values(&:to_i), # Save as Unix timestamp
          "timestamp" => Time.now.to_i
        }

        # 2. Ensure directory exists
        FileUtils.mkdir_p(File.dirname(@backup_path))

        # 3. ATOMIC WRITE: Write to temp, then rename
        temp_path = "#{@backup_path}.tmp"
        File.write(temp_path, JSON.generate(data))
        File.rename(temp_path, @backup_path)
        
        @last_backup = Time.now
      end

      def restore!
        return unless @backup_path && File.exist?(@backup_path)

        begin
          raw = JSON.parse(File.read(@backup_path))
          
          @store.clear
          @ttls.clear

          raw["store"].each { |k, v| @store[k] = v }
          raw["ttls"].each do |k, v|
            @ttls[k] = Time.at(v)
          end
        rescue => e
          warn "Telegem: Failed to restore backup: #{e.message}"
        end
      end

      private

      def expired?(key)
        @ttls[key] && Time.now > @ttls[key]
      end

      def auto_cleanup
        if (Time.now - @last_cleanup) > @cleanup_interval
          now = Time.now
          expired_keys = @ttls.select { |_, expires| now > expires }.keys
          expired_keys.each { |k| delete(k) }
          @last_cleanup = now
        end
      end

      def auto_backup
        if @backup_path && (Time.now - @last_backup) > @backup_interval
          backup!
        end
      end
    end
  end
end

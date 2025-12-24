module Telegem
  module Types
    class BaseType
      def initialize(data)
        @_raw_data = data || {}
        @_accessors_defined = {}
      end
      
      def method_missing(name, *args)
        return super if args.any? || block_given?
        
        define_accessor(name)
        
        if respond_to?(name)
          send(name)
        else
          super
        end
      end
      
      def respond_to_missing?(name, include_private = false)
        key = name.to_s
        camel_key = snake_to_camel(key)
        @_raw_data.key?(key) || @_raw_data.key?(camel_key) || super
      end
      
      def to_h
        @_raw_data.dup
      end
      
      alias_method :to_hash, :to_h
      
      def inspect
        "#<#{self.class.name} #{@_raw_data.inspect}>"
      end
      
      def to_s
        inspect
      end
      
      attr_reader :_raw_data
      
      private
      
      def define_accessor(name)
        return if @_accessors_defined[name]
        
        key = name.to_s
        camel_key = snake_to_camel(key)
        
        if @_raw_data.key?(key)
          define_singleton_method(name) { @_raw_data[key] }
        elsif @_raw_data.key?(camel_key)
          define_singleton_method(name) { @_raw_data[camel_key] }
        else
          define_singleton_method(name) do
            raise NoMethodError, 
                  "undefined method `#{name}' for #{self.class} with keys: #{@_raw_data.keys}"
          end
        end
        
        @_accessors_defined[name] = true
      end
      
      def snake_to_camel(str)
        str.gsub(/_([a-z])/) { $1.upcase }
      end
      
      def camel_to_snake(str)
        str.gsub(/([A-Z])/) { "_#{$1.downcase}" }.sub(/^_/, '')
      end
    end
    
    class User < BaseType
      COMMON_FIELDS = %w[id is_bot first_name last_name username
                        can_join_groups can_read_all_group_messages 
                        supports_inline_queries language_code 
                        is_premium added_to_attachment_menu 
                        can_connect_to_business].freeze
      
      def initialize(data)
        super(data)
        
        COMMON_FIELDS.each do |field|
          define_accessor(field.to_sym)
        end
      end
      
      def full_name
        [first_name, last_name].compact.join(' ')
      end
      
      def mention
        if username
          "@#{username}"
        elsif first_name
          first_name
        else
          "User ##{id}"
        end
      end
      
      def to_s
        full_name
      end
    end
    
    class Chat < BaseType
      COMMON_FIELDS = %w[id type username title first_name last_name
                        photo bio has_private_forwards 
                        has_restricted_voice_and_video_messages
                        description invite_link pinned_message 
                        permissions slow_mode_delay message_auto_delete_time
                        has_protected_content sticker_set_name 
                        can_set_sticker_set linked_chat_id location].freeze
      
      def initialize(data)
        super(data)
        
        COMMON_FIELDS.each do |field|
          define_accessor(field.to_sym)
        end
      end
      
      def private?
        type == 'private'
      end
      
      def group?
        type == 'group'
      end
      
      def supergroup?
        type == 'supergroup'
      end
      
      def channel?
        type == 'channel'
      end
      
      def to_s
        title || username || "Chat ##{id}"
      end
    end
    
    class MessageEntity < BaseType
      COMMON_FIELDS = %w[type offset length url user language
                        custom_emoji_id].freeze
      
      def initialize(data)
        super(data)
        
        COMMON_FIELDS.each do |field
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
        
        COMMON_FIELDS.each do |field|
          define_accessor(field.to_sym)
        end
        
        if @_raw_data['user'] && !@_raw_data['user'].is_a?(User)
          @_raw_data['user'] = User.new(@_raw_data['user'])
        end
      end
    end
    
    class Message < BaseType
      COMMON_FIELDS = %w[message_id from chat date edit_date 
                        text caption entities caption_entities 
                        audio document photo sticker video voice 
                        video_note contact location venue 
                        new_chat_members left_chat_member 
                        new_chat_title new_chat_photo 
                        delete_chat_photo group_chat_created 
                        supergroup_chat_created channel_chat_created 
                        migrate_to_chat_id migrate_from_chat_id 
                        pinned_message invoice successful_payment 
                        connected_website reply_markup via_bot 
                        forward_from forward_from_chat 
                        forward_from_message_id forward_signature 
                        forward_sender_name forward_date reply_to_message 
                        media_group_id author_signature 
                        has_protected_content].freeze
      
      def initialize(data)
        super(data)
        
        COMMON_FIELDS.each do |field|
          define_accessor(field.to_sym)
        end
        
        convert_complex_fields
      end
      
      def command?
        return false unless text && entities
        
        entities.any? { |e| e.type == 'bot_command' && 
                           text[e.offset, e.length]&.start_with?('/') }
      end
      
      def command_name
        return nil unless command?
        
        command_entity = entities.find { |e| e.type == 'bot_command' }
        return nil unless command_entity
        
        cmd = text[command_entity.offset, command_entity.length]
        return nil if cmd.nil? || cmd.length <= 1
        
        cmd = cmd[1..-1]
        cmd.split('@').first.strip
      end
      
      def command_args
        return nil unless command?
        
        command_entity = entities.find { |e| e.type == 'bot_command' }
        return nil unless command_entity
        
        args_start = command_entity.offset + command_entity.length
        remaining = text[args_start..-1]
        
        next_entity = entities.select { |e| e.offset >= args_start }
                              .min_by(&:offset)
        
        if next_entity
          args_end = next_entity.offset - 1
          text[args_start..args_end]&.strip
        else
          remaining&.strip
        end
      end
      
      def reply?
        !!reply_to_message
      end
      
      def has_media?
        !!(audio || document || photo || video || voice || video_note || sticker)
      end
      
      def media_type
        return :audio if audio
        return :document if document
        return :photo if photo
        return :video if video
        return :voice if voice
        return :video_note if video_note
        return :sticker if sticker
        nil
      end
      
      private
      
      def convert_complex_fields
        if @_raw_data['date'] && !@_raw_data['date'].is_a?(Time)
          @_raw_data['date'] = Time.at(@_raw_data['date'])
        end
        
        if @_raw_data['edit_date'] && !@_raw_data['edit_date'].is_a?(Time)
          @_raw_data['edit_date'] = Time.at(@_raw_data['edit_date'])
        end
        
        if @_raw_data['forward_date'] && !@_raw_data['forward_date'].is_a?(Time)
          @_raw_data['forward_date'] = Time.at(@_raw_data['forward_date'])
        end
        
        @_raw_data['from'] = User.new(@_raw_data['from']) if @_raw_data['from'] && !@_raw_data['from'].is_a?(User)
        @_raw_data['chat'] = Chat.new(@_raw_data['chat']) if @_raw_data['chat'] && !@_raw_data['chat'].is_a?(Chat)
        @_raw_data['via_bot'] = User.new(@_raw_data['via_bot']) if @_raw_data['via_bot'] && !@_raw_data['via_bot'].is_a?(User)
        @_raw_data['forward_from'] = User.new(@_raw_data['forward_from']) if @_raw_data['forward_from'] && !@_raw_data['forward_from'].is_a?(User)
        @_raw_data['forward_from_chat'] = Chat.new(@_raw_data['forward_from_chat']) if @_raw_data['forward_from_chat'] && !@_raw_data['forward_from_chat'].is_a?(Chat)
        @_raw_data['left_chat_member'] = User.new(@_raw_data['left_chat_member']) if @_raw_data['left_chat_member'] && !@_raw_data['left_chat_member'].is_a?(User)
        
        if @_raw_data['entities'] && @_raw_data['entities'].is_a?(Array)
          @_raw_data['entities'] = @_raw_data['entities'].map do |e|
            e.is_a?(MessageEntity) ? e : MessageEntity.new(e)
          end
        end
        
        if @_raw_data['caption_entities'] && @_raw_data['caption_entities'].is_a?(Array)
          @_raw_data['caption_entities'] = @_raw_data['caption_entities'].map do |e|
            e.is_a?(MessageEntity) ? e : MessageEntity.new(e)
          end
        end
        
        if @_raw_data['reply_to_message'] && !@_raw_data['reply_to_message'].is_a?(Message)
          @_raw_data['reply_to_message'] = Message.new(@_raw_data['reply_to_message'])
        end
        
        if @_raw_data['pinned_message'] && !@_raw_data['pinned_message'].is_a?(Message)
          @_raw_data['pinned_message'] = Message.new(@_raw_data['pinned_message'])
        end
        
        if @_raw_data['new_chat_members'] && @_raw_data['new_chat_members'].is_a?(Array)
          @_raw_data['new_chat_members'] = @_raw_data['new_chat_members'].map do |u|
            u.is_a?(User) ? u : User.new(u)
          end
        end
      end
    end
    
    class CallbackQuery < BaseType
      COMMON_FIELDS = %w[id from message inline_message_id chat_instance data game_short_name].freeze
      
      def initialize(data)
        super(data)
        
        COMMON_FIELDS.each do |field|
          define_accessor(field.to_sym)
        end
        
        if @_raw_data['from'] && !@_raw_data['from'].is_a?(User)
          @_raw_data['from'] = User.new(@_raw_data['from'])
        end
        
        if @_raw_data['message'] && !@_raw_data['message'].is_a?(Message)
          @_raw_data['message'] = Message.new(@_raw_data['message'])
        end
      end
      
      def from_user?
        !!from
      end
      
      def message?
        !!message
      end
      
      def inline_message?
        !!inline_message_id
      end
    end
    
    class Update < BaseType
      COMMON_FIELDS = %w[update_id message edited_message channel_post 
                        edited_channel_post inline_query chosen_inline_result 
                        callback_query shipping_query pre_checkout_query 
                        poll poll_answer my_chat_member chat_member 
                        chat_join_request].freeze
      
      def initialize(data)
        super(data)
        
        COMMON_FIELDS.each do |field|
          define_accessor(field.to_sym)
        end
        
        convert_update_objects
      end
      
      def type
        return :message if message
        return :edited_message if edited_message
        return :channel_post if channel_post
        return :edited_channel_post if edited_channel_post
        return :inline_query if inline_query
        return :chosen_inline_result if chosen_inline_result
        return :callback_query if callback_query
        return :shipping_query if shipping_query
        return :pre_checkout_query if pre_checkout_query
        return :poll if poll
        return :poll_answer if poll_answer
        return :my_chat_member if my_chat_member
        return :chat_member if chat_member
        return :chat_join_request if chat_join_request
        :unknown
      end
      
      def from
        case type
        when :message, :edited_message
          message.from
        when :channel_post, :edited_channel_post
          channel_post.from
        when :inline_query
          inline_query.from
        when :chosen_inline_result
          chosen_inline_result.from
        when :callback_query
          callback_query.from
        when :shipping_query
          shipping_query.from
        when :pre_checkout_query
          pre_checkout_query.from
        when :my_chat_member, :chat_member
          my_chat_member&.from || chat_member&.from
        when :chat_join_request
          chat_join_request.from
        else
          nil
        end
      end
      
      private
      
      def convert_update_objects
        @_raw_data['message'] = Message.new(@_raw_data['message']) if @_raw_data['message'] && !@_raw_data['message'].is_a?(Message)
        @_raw_data['edited_message'] = Message.new(@_raw_data['edited_message']) if @_raw_data['edited_message'] && !@_raw_data['edited_message'].is_a?(Message)
        @_raw_data['channel_post'] = Message.new(@_raw_data['channel_post']) if @_raw_data['channel_post'] && !@_raw_data['channel_post'].is_a?(Message)
        @_raw_data['edited_channel_post'] = Message.new(@_raw_data['edited_channel_post']) if @_raw_data['edited_channel_post'] && !@_raw_data['edited_channel_post'].is_a?(Message)
        
        if @_raw_data['callback_query'] && !@_raw_data['callback_query'].is_a?(CallbackQuery)
          @_raw_data['callback_query'] = CallbackQuery.new(@_raw_data['callback_query'])
        end
      end
    end
  end
end
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
      
      # helpers for converting nested objects
      def wrap(key, klass)
        if @_raw_data[key] && !@_raw_data[key].is_a?(klass)
          @_raw_data[key] = klass.new(@_raw_data[key])
        end
      end
      
      def wrap_array(key, klass)
        if @_raw_data[key] && @_raw_data[key].is_a?(Array)
          @_raw_data[key] = @_raw_data[key].map do |v|
            v.is_a?(klass) ? v : klass.new(v)
          end
        end
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
        # time conversions
        @_raw_data['date'] = Time.at(@_raw_data['date']) if @_raw_data['date'] && !@_raw_data['date'].is_a?(Time)
        @_raw_data['edit_date'] = Time.at(@_raw_data['edit_date']) if @_raw_data['edit_date'] && !@_raw_data['edit_date'].is_a?(Time)
        @_raw_data['forward_date'] = Time.at(@_raw_data['forward_date']) if @_raw_data['forward_date'] && !@_raw_data['forward_date'].is_a?(Time)

        # basic object wrappers
        wrap('from', User)
        wrap('chat', Chat)
        wrap('via_bot', User)
        wrap('forward_from', User)
        wrap('forward_from_chat', Chat)
        wrap('left_chat_member', User)

        wrap_array('entities', MessageEntity)
        wrap_array('caption_entities', MessageEntity)

        wrap('reply_to_message', Message)
        wrap('pinned_message', Message)
        wrap_array('new_chat_members', User)

        # media and other nested types
        wrap('contact', Contact)
        wrap('location', Location)
        wrap('venue', Venue)
        wrap('dice', Dice)
        wrap('poll', Poll)
        wrap('proximity_alert_triggered', ProximityAlertTriggered)
        wrap('web_app_data', WebAppData)

        wrap('animation', Animation)
        wrap('audio', Audio)
        wrap('document', Document)
        wrap('video', Video)
        wrap('voice', Voice)
        wrap('video_note', VideoNote)
        wrap('sticker', Sticker)

        wrap('invoice', Invoice)
        wrap('successful_payment', SuccessfulPayment)
        wrap('reply_markup', BaseType)

        wrap('passport_data', PassportData)

        wrap('video_chat_scheduled', VideoChatScheduled)
        wrap('video_chat_started', VideoChatStarted)
        wrap('video_chat_ended', VideoChatEnded)
        wrap('video_chat_participants_invited', VideoChatParticipantsInvited)
        wrap('video_chat_location', VideoChatLocation)

        # new message event objects introduced in later API versions
        wrap('message_auto_delete_timer_changed', MessageAutoDeleteTimerChanged)
        wrap('forum_topic_created', ForumTopicCreated)
        wrap('forum_topic_edited', ForumTopicEdited)
        wrap('forum_topic_closed', ForumTopicClosed)
        wrap('forum_topic_reopened', ForumTopicReopened)
        wrap('general_forum_topic_hidden', GeneralForumTopicHidden)
        wrap('general_forum_topic_unhidden', GeneralForumTopicUnhidden)
        wrap('write_access_allowed', WriteAccessAllowed)

        # arrays of sizes and photos
        wrap_array('photo', PhotoSize)
        wrap_array('new_chat_photo', PhotoSize)

        # fall back to original media wrapper for backward compatibility
        wrap_media_objects
      end
      
      def wrap_media_objects
        # Media files (fall‑back to generic types if no specific class defined)
        @_raw_data['document'] = Document.new(@_raw_data['document']) if @_raw_data['document'] && !@_raw_data['document'].is_a?(Document)
        @_raw_data['animation'] = Animation.new(@_raw_data['animation']) if @_raw_data['animation'] && !@_raw_data['animation'].is_a?(Animation)
        @_raw_data['audio'] = Audio.new(@_raw_data['audio']) if @_raw_data['audio'] && !@_raw_data['audio'].is_a?(Audio)
        @_raw_data['video'] = Video.new(@_raw_data['video']) if @_raw_data['video'] && !@_raw_data['video'].is_a?(Video)
        @_raw_data['voice'] = Voice.new(@_raw_data['voice']) if @_raw_data['voice'] && !@_raw_data['voice'].is_a?(Voice)
        @_raw_data['video_note'] = VideoNote.new(@_raw_data['video_note']) if @_raw_data['video_note'] && !@_raw_data['video_note'].is_a?(VideoNote)
        @_raw_data['sticker'] = Sticker.new(@_raw_data['sticker']) if @_raw_data['sticker'] && !@_raw_data['sticker'].is_a?(Sticker)

        # Photo array
        if @_raw_data['photo'] && @_raw_data['photo'].is_a?(Array)
          @_raw_data['photo'] = @_raw_data['photo'].map do |p|
            p.is_a?(PhotoSize) ? p : PhotoSize.new(p)
          end
        end

        # Contact, location, venue
        @_raw_data['contact'] = Contact.new(@_raw_data['contact']) if @_raw_data['contact'] && !@_raw_data['contact'].is_a?(Contact)
        @_raw_data['location'] = Location.new(@_raw_data['location']) if @_raw_data['location'] && !@_raw_data['location'].is_a?(Location)
        @_raw_data['venue'] = Venue.new(@_raw_data['venue']) if @_raw_data['venue'] && !@_raw_data['venue'].is_a?(Venue)

        # Payment & other
        @_raw_data['invoice'] = Invoice.new(@_raw_data['invoice']) if @_raw_data['invoice'] && !@_raw_data['invoice'].is_a?(Invoice)
        @_raw_data['successful_payment'] = SuccessfulPayment.new(@_raw_data['successful_payment']) if @_raw_data['successful_payment'] && !@_raw_data['successful_payment'].is_a?(SuccessfulPayment)
        @_raw_data['reply_markup'] = BaseType.new(@_raw_data['reply_markup']) if @_raw_data['reply_markup'] && !@_raw_data['reply_markup'].is_a?(BaseType)

        # Chat photo array
        if @_raw_data['new_chat_photo'] && @_raw_data['new_chat_photo'].is_a?(Array)
          @_raw_data['new_chat_photo'] = @_raw_data['new_chat_photo'].map do |p|
            p.is_a?(PhotoSize) ? p : PhotoSize.new(p)
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
        wrap('message', Message)
        wrap('edited_message', Message)
        wrap('channel_post', Message)
        wrap('edited_channel_post', Message)

        wrap('inline_query', InlineQuery)
        wrap('chosen_inline_result', ChosenInlineResult)
        wrap('callback_query', CallbackQuery)
        wrap('shipping_query', ShippingQuery)
        wrap('pre_checkout_query', PreCheckoutQuery)
        wrap('poll', Poll)
        wrap('poll_answer', PollAnswer)
        wrap('my_chat_member', ChatMemberUpdated)
        wrap('chat_member', ChatMemberUpdated)
        wrap('chat_join_request', ChatJoinRequest)
        wrap('forum_topic_created', ForumTopicCreated)
        wrap('forum_topic_edited', ForumTopicEdited)
        wrap('forum_topic_closed', ForumTopicClosed)
        wrap('forum_topic_reopened', ForumTopicReopened)
        wrap('general_forum_topic_hidden', GeneralForumTopicHidden)
        wrap('general_forum_topic_unhidden', GeneralForumTopicUnhidden)
        wrap('write_access_allowed', WriteAccessAllowed)
      end
    end

    # additional types returned by various methods / updates
    class PhotoSize < BaseType; end
    class Audio < BaseType; end
    class Document < BaseType; end
    class Video < BaseType; end
    class Voice < BaseType; end
    class VideoNote < BaseType; end
    class Animation < BaseType; end
    class Sticker < BaseType; end
    class Contact < BaseType; end
    class Dice < BaseType; end

    class Location < BaseType; end
    class Venue < BaseType; end
    class ProximityAlertTriggered < BaseType; end
    class WebAppData < BaseType; end
    class PassportData < BaseType; end

    class Invoice < BaseType; end
    class SuccessfulPayment < BaseType; end
    class ShippingAddress < BaseType; end
    class OrderInfo < BaseType; end

    class ShippingQuery < BaseType
      def initialize(data)
        super(data)
        wrap('from', User)
        wrap('shipping_address', ShippingAddress)
      end
    end

    class PreCheckoutQuery < BaseType
      def initialize(data)
        super(data)
        wrap('from', User)
        wrap('shipping_address', ShippingAddress)
        wrap('order_info', OrderInfo)
      end
    end

    class PollOption < BaseType; end
    class PollAnswer < BaseType; end

    class Poll < BaseType
      def initialize(data)
        super(data)
        wrap_array('options', PollOption)
        wrap_array('explanation_entities', MessageEntity)
      end
    end

    class ChatPermissions < BaseType; end
    class ChatPhoto < BaseType; end
    class ChatInviteLink < BaseType; end

    # status-specific chat member objects. they inherit from ChatMember
    class ChatMember < BaseType; end
    class ChatMemberOwner < ChatMember; end
    class ChatMemberAdministrator < ChatMember; end
    class ChatMemberMember < ChatMember; end
    class ChatMemberRestricted < ChatMember; end
    class ChatMemberLeft < ChatMember; end
    class ChatMemberBanned < ChatMember; end

    class ChatAdministratorRights < BaseType; end

    class ChatMemberUpdated < BaseType
      def initialize(data)
        super(data)
        wrap('chat', Chat)
        wrap('from', User)
        wrap_member('old_chat_member')
        wrap_member('new_chat_member')
        wrap('invite_link', ChatInviteLink)
        if @_raw_data['date'] && !@_raw_data['date'].is_a?(Time)
          @_raw_data['date'] = Time.at(@_raw_data['date'])
        end
      end

      private

      def wrap_member(key)
        return unless @_raw_data[key]
        status = @_raw_data[key]['status']
        klass = case status
                when 'creator' then ChatMemberOwner
                when 'administrator' then ChatMemberAdministrator
                when 'member' then ChatMemberMember
                when 'restricted' then ChatMemberRestricted
                when 'left' then ChatMemberLeft
                when 'kicked' then ChatMemberBanned
                else ChatMember
                end
        @_raw_data[key] = klass.new(@_raw_data[key])
      end
    end

    class ChatJoinRequest < BaseType
      def initialize(data)
        super(data)
        wrap('chat', Chat)
        wrap('from', User)
        wrap('invite_link', ChatInviteLink)
        if @_raw_data['date'] && !@_raw_data['date'].is_a?(Time)
          @_raw_data['date'] = Time.at(@_raw_data['date'])
        end
      end
    end

    class InlineQuery < BaseType
      def initialize(data)
        super(data)
        wrap('from', User)
        wrap('location', Location)
      end
    end

    class ChosenInlineResult < BaseType
      def initialize(data)
        super(data)
        wrap('from', User)
        wrap('location', Location)
      end
    end

    class InlineQueryResult < BaseType; end
    class InlineQueryResultArticle < InlineQueryResult; end
    class InlineQueryResultPhoto < InlineQueryResult; end
    class InlineQueryResultGif < InlineQueryResult; end
    class InlineQueryResultMpeg4Gif < InlineQueryResult; end
    class InlineQueryResultVideo < InlineQueryResult; end
    class InlineQueryResultAudio < InlineQueryResult; end
    class InlineQueryResultVoice < InlineQueryResult; end
    class InlineQueryResultDocument < InlineQueryResult; end
    class InlineQueryResultLocation < InlineQueryResult; end
    class InlineQueryResultVenue < InlineQueryResult; end
    class InlineQueryResultContact < InlineQueryResult; end
    class InlineQueryResultGame < InlineQueryResult; end
    class InlineQueryResultSticker < InlineQueryResult; end
    class InlineQueryResultCachedPhoto < InlineQueryResult; end
    class InlineQueryResultCachedGif < InlineQueryResult; end
    class InlineQueryResultCachedMpeg4Gif < InlineQueryResult; end
    class InlineQueryResultCachedSticker < InlineQueryResult; end
    class InlineQueryResultCachedDocument < InlineQueryResult; end
    class InlineQueryResultCachedVideo < InlineQueryResult; end
    class InlineQueryResultCachedAudio < InlineQueryResult; end
    class InlineQueryResultCachedVoice < InlineQueryResult; end

    class UserProfilePhotos < BaseType
      def initialize(data)
        super(data)
        wrap_array('photos', PhotoSize)
      end
    end

    class UserProfileAudios < BaseType
      def initialize(data)
        super(data)
        wrap_array('audios', Audio)
      end
    end

    # generic utility objects returned by the API
    class File < BaseType; end
    class ResponseParameters < BaseType; end
    class MaskPosition < BaseType; end
    class StickerSet < BaseType; end

    # new message event payloads (each a simple wrapper)
    class MessageAutoDeleteTimerChanged < BaseType; end
    class ForumTopicCreated < BaseType; end
    class ForumTopicEdited < BaseType; end
    class ForumTopicClosed < BaseType; end
    class ForumTopicReopened < BaseType; end
    class GeneralForumTopicHidden < BaseType; end
    class GeneralForumTopicUnhidden < BaseType; end
    class WriteAccessAllowed < BaseType; end

    class BotCommand < BaseType; end
    class BotCommandScope < BaseType; end
    class WebhookInfo < BaseType; end

    class VideoChatScheduled < BaseType; end
    class VideoChatStarted < BaseType; end
    class VideoChatEnded < BaseType; end
    class VideoChatParticipantsInvited < BaseType; end
    class VideoChatLocation < BaseType; end

  end
end
require 'json'

module Telegem
  module Core
    class Context
      attr_accessor :update, :bot, :state, :match, :session, :scene
      
      def initialize(update, bot)
        @update = update
        @bot = bot
        @state = {}
        @session = {}
        @match = nil
        @scene = nil
      end
      
      def message
        @update.message
      end
      
      def callback_query
        @update.callback_query
      end
      
      def inline_query
        @update.inline_query
      end
      
      def from
        message&.from || callback_query&.from || inline_query&.from
      end
      
      def chat
        message&.chat || callback_query&.message&.chat
      end
      
      def data
        callback_query&.data
      end
      
      def query
        inline_query&.query
      end
      
      def reply(text, **options)
        return nil unless chat
        
        params = { chat_id: chat.id, text: text }.merge(options)
        @bot.api.call('sendMessage', params)
      end
      
      def edit_message_text(text, **options)
        return nil unless message && chat
        
        params = {
          chat_id: chat.id,
          message_id: message.message_id,
          text: text
        }.merge(options)
        
        @bot.api.call('editMessageText', params)
      end
      
      def delete_message(message_id = nil)
        mid = message_id || message&.message_id
        return nil unless mid && chat
        
        @bot.api.call('deleteMessage', chat_id: chat.id, message_id: mid)
      end
      
      def answer_callback_query(text: nil, show_alert: false, **options)
        return nil unless callback_query
        
        params = {
          callback_query_id: callback_query.id,
          show_alert: show_alert
        }.merge(options)
        
        params[:text] = text if text
        @bot.api.call('answerCallbackQuery', params)
      end
      
      def answer_inline_query(results, **options)
        return nil unless inline_query
        
        params = {
          inline_query_id: inline_query.id,
          results: results.to_json
        }.merge(options)
        
        @bot.api.call('answerInlineQuery', params)
      end
      
      def photo(photo, caption: nil, **options)
        return nil unless chat
        
        params = { chat_id: chat.id, caption: caption }.merge(options)
        
        if file_object?(photo)
          @bot.api.upload('sendPhoto', params.merge(photo: photo))
        else
          @bot.api.call('sendPhoto', params.merge(photo: photo))
        end
      end
      
      def document(document, caption: nil, **options)
        return nil unless chat
        
        params = { chat_id: chat.id, caption: caption }.merge(options)
        
        if file_object?(document)
          @bot.api.upload('sendDocument', params.merge(document: document))
        else
          @bot.api.call('sendDocument', params.merge(document: document))
        end
      end
      
      def audio(audio, caption: nil, **options)
        return nil unless chat
        
        params = { chat_id: chat.id, caption: caption }.merge(options)
        
        if file_object?(audio)
          @bot.api.upload('sendAudio', params.merge(audio: audio))
        else
          @bot.api.call('sendAudio', params.merge(audio: audio))
        end
      end
      
      def video(video, caption: nil, **options)
        return nil unless chat
        
        params = { chat_id: chat.id, caption: caption }.merge(options)
        
        if file_object?(video)
          @bot.api.upload('sendVideo', params.merge(video: video))
        else
          @bot.api.call('sendVideo', params.merge(video: video))
        end
      end
      
      def voice(voice, caption: nil, **options)
        return nil unless chat
        
        params = { chat_id: chat.id, caption: caption }.merge(options)
        
        if file_object?(voice)
          @bot.api.upload('sendVoice', params.merge(voice: voice))
        else
          @bot.api.call('sendVoice', params.merge(voice: voice))
        end
      end
      
      def sticker(sticker, **options)
        return nil unless chat
        
        params = { chat_id: chat.id, sticker: sticker }.merge(options)
        @bot.api.call('sendSticker', params)
      end
      
      def location(latitude, longitude, **options)
        return nil unless chat
        
        params = { 
          chat_id: chat.id, 
          latitude: latitude, 
          longitude: longitude 
        }.merge(options)
        
        @bot.api.call('sendLocation', params)
      end
      
      def send_chat_action(action, **options)
        return nil unless chat
        
        params = { chat_id: chat.id, action: action }.merge(options)
        @bot.api.call('sendChatAction', params)
      end
      
      def forward_message(from_chat_id, message_id, **options)
        return nil unless chat
        
        params = { 
          chat_id: chat.id, 
          from_chat_id: from_chat_id, 
          message_id: message_id 
        }.merge(options)
        
        @bot.api.call('forwardMessage', params)
      end
      
      def copy_message(from_chat_id, message_id, **options)
        return nil unless chat
        
        params = { 
          chat_id: chat.id, 
          from_chat_id: from_chat_id, 
          message_id: message_id 
        }.merge(options)
        
        @bot.api.call('copyMessage', params)
      end
      
      def pin_message(message_id, **options)
        return nil unless chat
        
        params = { chat_id: chat.id, message_id: message_id }.merge(options)
        @bot.api.call('pinChatMessage', params)
      end
      
      def unpin_message(**options)
        return nil unless chat
        
        params = { chat_id: chat.id }.merge(options)
        @bot.api.call('unpinChatMessage', params)
      end
      
      def kick_chat_member(user_id, **options)
        return nil unless chat
        
        params = { chat_id: chat.id, user_id: user_id }.merge(options)
        @bot.api.call('kickChatMember', params)
      end
      
      def ban_chat_member(user_id, **options)
        return nil unless chat
        
        params = { chat_id: chat.id, user_id: user_id }.merge(options)
        @bot.api.call('banChatMember', params)
      end
      
      def unban_chat_member(user_id, **options)
        return nil unless chat
        
        params = { chat_id: chat.id, user_id: user_id }.merge(options)
        @bot.api.call('unbanChatMember', params)
      end
      
      def get_chat_administrators(**options)
        return nil unless chat
        
        params = { chat_id: chat.id }.merge(options)
        @bot.api.call('getChatAdministrators', params)
      end
      
      def get_chat_members_count(**options)
        return nil unless chat
        
        params = { chat_id: chat.id }.merge(options)
        @bot.api.call('getChatMembersCount', params)
      end
      
      def get_chat(**options)
        return nil unless chat
        
        params = { chat_id: chat.id }.merge(options)
        @bot.api.call('getChat', params)
      end
      
      def keyboard(&block)
        Telegem::Markup.keyboard(&block)
      end
      
      def inline_keyboard(&block)
        Telegem::Markup.inline(&block)
      end
      
      def reply_with_keyboard(text, keyboard_markup, **options)
        return nil unless chat
        
        reply_markup = keyboard_markup.is_a?(Hash) ? keyboard_markup : keyboard_markup.to_h
        reply(text, reply_markup: reply_markup, **options)
      end
      
      def reply_with_inline_keyboard(text, inline_markup, **options)
        return nil unless chat
        
        reply_markup = inline_markup.is_a?(Hash) ? inline_markup : inline_markup.to_h
        reply(text, reply_markup: reply_markup, **options)
      end
      
      def remove_keyboard(text = nil, **options)
        return nil unless chat
        
        reply_markup = Telegem::Markup.remove(**options.slice(:selective))
        if text
          reply(text, reply_markup: reply_markup, **options.except(:selective))
        else
          reply_markup
        end
      end
      
      def edit_message_reply_markup(reply_markup, **options)
        return nil unless message && chat
        
        params = {
          chat_id: chat.id,
          message_id: message.message_id,
          reply_markup: reply_markup
        }.merge(options)
        
        @bot.api.call('editMessageReplyMarkup', params)
      end
      
      def typing(**options)
        send_chat_action('typing', **options)
      end
      
      def uploading_photo(**options)
        send_chat_action('upload_photo', **options)
      end
      
      def uploading_video(**options)
        send_chat_action('upload_video', **options)
      end
      
      def uploading_audio(**options)
        send_chat_action('upload_audio', **options)
      end
      
      def uploading_document(**options)
        send_chat_action('upload_document', **options)
      end
      
      def with_typing(&block)
        typing_request = typing
        
        result = block.call
        
        result
      end
      
      def command?
        message&.command? || false
      end
      
      def command_args
        message&.command_args if command?
      end
      
      def enter_scene(scene_name, **options)
        return nil unless @bot.scenes[scene_name]
        
        @scene = scene_name
        @bot.scenes[scene_name].enter(self, **options)
      end
      
      def leave_scene(**options)
        return nil unless @scene && @bot.scenes[@scene]
        
        scene_name = @scene
        @scene = nil
        @bot.scenes[scene_name].leave(self, **options)
      end
      
      def current_scene
        @bot.scenes[@scene] if @scene
      end
      
      def logger
        @bot.logger
      end
      
      def raw_update
        @update._raw_data
      end
      
      def api
        @bot.api
      end
      
      def user_id
        from&.id
      end
      
      private
      
      def file_object?(obj)
        obj.is_a?(File) || obj.is_a?(StringIO) || obj.is_a?(Tempfile) ||
          (obj.is_a?(String) && File.exist?(obj))
      end
    end
  end
end
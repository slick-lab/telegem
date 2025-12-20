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

      # Message shortcuts
      def message
        @update.message
      end

      def callback_query
        @update.callback_query
      end

      def inline_query
        @update.inline_query
      end

      # Entity shortcuts
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

      # Action methods
      def reply(text, **options)
        Async do
          params = { chat_id: chat.id, text: text }.merge(options)
          await @bot.api.call('sendMessage', params)
        end
      end

      def edit_message_text(text, **options)
        return Async::Task.new(nil) unless message

        Async do
          params = {
            chat_id: chat.id,
            message_id: message.message_id,
            text: text
          }.merge(options)

          await @bot.api.call('editMessageText', params)
        end
      end

      def delete_message(message_id = nil)
        mid = message_id || message&.message_id
        return Async::Task.new(nil) unless mid && chat

        Async do
          await @bot.api.call('deleteMessage', chat_id: chat.id, message_id: mid)
        end
      end

      def answer_callback_query(text: nil, show_alert: false, **options)
        return Async::Task.new(nil) unless callback_query

        Async do
          params = {
            callback_query_id: callback_query.id,
            show_alert: show_alert
          }.merge(options)

          params[:text] = text if text
          await @bot.api.call('answerCallbackQuery', params)
        end
      end

      def answer_inline_query(results, **options)
        return Async::Task.new(nil) unless inline_query

        Async do
          params = {
            inline_query_id: inline_query.id,
            results: results.to_json
          }.merge(options)

          await @bot.api.call('answerInlineQuery', params)
        end
      end

      # Media methods
      def photo(photo, caption: nil, **options)
        Async do
          params = { chat_id: chat.id, caption: caption }.merge(options)

          if file_object?(photo)
            await @bot.api.upload('sendPhoto', params.merge(photo: photo))
          else
            await @bot.api.call('sendPhoto', params.merge(photo: photo))
          end
        end
      end

      def document(document, caption: nil, **options)
        Async do
          params = { chat_id: chat.id, caption: caption }.merge(options)

          if file_object?(document)
            await @bot.api.upload('sendDocument', params.merge(document: document))
          else
            await @bot.api.call('sendDocument', params.merge(document: document))
          end
        end
      end

      def audio(audio, caption: nil, **options)
        Async do
          params = { chat_id: chat.id, caption: caption }.merge(options)

          if file_object?(audio)
            await @bot.api.upload('sendAudio', params.merge(audio: audio))
          else
            await @bot.api.call('sendAudio', params.merge(audio: audio))
          end
        end
      end

      def video(video, caption: nil, **options)
        Async do
          params = { chat_id: chat.id, caption: caption }.merge(options)

          if file_object?(video)
            await @bot.api.upload('sendVideo', params.merge(video: video))
          else
            await @bot.api.call('sendVideo', params.merge(video: video))
          end
        end
      end

      def voice(voice, caption: nil, **options)
        Async do
          params = { chat_id: chat.id, caption: caption }.merge(options)

          if file_object?(voice)
            await @bot.api.upload('sendVoice', params.merge(voice: voice))
          else
            await @bot.api.call('sendVoice', params.merge(voice: voice))
          end
        end
      end

      def sticker(sticker, **options)
        Async do
          params = { chat_id: chat.id, sticker: sticker }.merge(options)
          await @bot.api.call('sendSticker', params)
        end
      end

      def location(latitude, longitude, **options)
        Async do
          params = { 
            chat_id: chat.id, 
            latitude: latitude, 
            longitude: longitude 
          }.merge(options)

          await @bot.api.call('sendLocation', params)
        end
      end

      def send_chat_action(action, **options)
        Async do
          params = { chat_id: chat.id, action: action }.merge(options)
          await @bot.api.call('sendChatAction', params)
        end
      end

      def forward_message(from_chat_id, message_id, **options)
        Async do
          params = { 
            chat_id: chat.id, 
            from_chat_id: from_chat_id, 
            message_id: message_id 
          }.merge(options)

          await @bot.api.call('forwardMessage', params)
        end
      end

      def pin_message(message_id, **options)
        Async do
          params = { chat_id: chat.id, message_id: message_id }.merge(options)
          await @bot.api.call('pinChatMessage', params)
        end
      end

      def unpin_message(**options)
        Async do
          params = { chat_id: chat.id }.merge(options)
          await @bot.api.call('unpinChatMessage', params)
        end
      end

      def kick_chat_member(user_id, **options)
        Async do
          params = { chat_id: chat.id, user_id: user_id }.merge(options)
          await @bot.api.call('kickChatMember', params)
        end
      end

      def ban_chat_member(user_id, **options)
        Async do
          params = { chat_id: chat.id, user_id: user_id }.merge(options)
          await @bot.api.call('banChatMember', params)
        end
      end

      def unban_chat_member(user_id, **options)
        Async do
          params = { chat_id: chat.id, user_id: user_id }.merge(options)
          await @bot.api.call('unbanChatMember', params)
        end
      end

      def get_chat_administrators(**options)
        Async do
          params = { chat_id: chat.id }.merge(options)
          await @bot.api.call('getChatAdministrators', params)
        end
      end

      def get_chat_members_count(**options)
        Async do
          params = { chat_id: chat.id }.merge(options)
          await @bot.api.call('getChatMembersCount', params)
        end
      end

      def get_chat(**options)
        Async do
          params = { chat_id: chat.id }.merge(options)
          await @bot.api.call('getChat', params)
        end
      end

      # Keyboard helpers
      def keyboard(&block)
        require 'lib/markup/keyboard'
        Telegem::Markup.keyboard(&block)
      end

      def inline_keyboard(&block)
        require 'telegem/markup/keyboard'
        Telegem::Markup.inline(&block)
      end

      def reply_with_keyboard(text, keyboard_markup, **options)
        Async do
          reply_markup = keyboard_markup.is_a?(Hash) ? keyboard_markup : keyboard_markup.to_h
          await reply(text, reply_markup: reply_markup, **options)
        end
      end

      def reply_with_inline_keyboard(text, inline_markup, **options)
        Async do
          reply_markup = inline_markup.is_a?(Hash) ? inline_markup : inline_markup.to_h
          await reply(text, reply_markup: reply_markup, **options)
        end
      end

      def remove_keyboard(text = nil, **options)
        Async do
          reply_markup = Telegem::Markup.remove(**options.slice(:selective))
          if text
            await reply(text, reply_markup: reply_markup, **options.except(:selective))
          else
            reply_markup
          end
        end
      end

      def edit_message_reply_markup(reply_markup, **options)
        return Async::Task.new(nil) unless message

        Async do
          params = {
            chat_id: chat.id,
            message_id: message.message_id,
            reply_markup: reply_markup
          }.merge(options)

          await @bot.api.call('editMessageReplyMarkup', params)
        end
      end

      # Chat action shortcuts
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
        Async do
          await typing
          result = block.call
          result.is_a?(Async::Task) ? await(result) : result
        end
      end

      # Command detection
      def command?
        message&.command? || false
      end

      def command_args
        message&.command_args if command?
      end

      # Scene management
      def enter_scene(scene_name, **options)
        Async do
          @scene = scene_name
          if @bot.scenes[scene_name]
            await @bot.scenes[scene_name].enter(self, **options)
          end
        end
      end

      def leave_scene(**options)
        Async do
          return unless @scene
          if @bot.scenes[@scene]
            await @bot.scenes[@scene].leave(self, **options)
          end
          @scene = nil
        end
      end

      def current_scene
        @bot.scenes[@scene] if @scene
      end

      # Utilities
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
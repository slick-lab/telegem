module Telegem
  module Types
    class BaseType
      def initialize(data)
        @_raw_data = data || {}
      end
      
      def method_missing(name, *args)
        key = name.to_s
        return @_raw_data[key] if @_raw_data.key?(key)
        
        camel_key = snake_to_camel(key)
        return @_raw_data[camel_key] if @_raw_data.key?(camel_key)
        
        super
      end
      
      def respond_to_missing?(name, include_private = false)
        key = name.to_s
        camel_key = snake_to_camel(key)
        @_raw_data.key?(key) || @_raw_data.key?(camel_key) || super
      end
      
      attr_reader :_raw_data
      
      private
      
      def snake_to_camel(str)
        str.gsub(/_([a-z])/) { $1.upcase }
      end
    end
    
    class User < BaseType
      attr_reader :id, :is_bot, :first_name, :last_name, :username,
                  :can_join_groups, :can_read_all_group_messages, :supports_inline_queries
      
      def initialize(data)
        super(data)
        
        @id = data['id']
        @is_bot = data['is_bot']
        @first_name = data['first_name']
        @last_name = data['last_name']
        @username = data['username']
        @can_join_groups = data['can_join_groups']
        @can_read_all_group_messages = data['can_read_all_group_messages']
        @supports_inline_queries = data['supports_inline_queries']
      end
      
      def full_name
        [first_name, last_name].compact.join(' ')
      end
      
      def mention
        username ? "@#{username}" : first_name
      end
    end
    
    class Chat < BaseType
      attr_reader :id, :type, :username, :title
      
      def initialize(data)
        super(data)
        
        @id = data['id']
        @type = data['type']
        @username = data['username']
        @title = data['title']
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
    end
    
    class MessageEntity < BaseType
      attr_reader :type, :offset, :length, :url, :user, :language
      
      def initialize(data)
        super(data)
        
        @type = data['type']
        @offset = data['offset']
        @length = data['length']
        @url = data['url']
        @user = User.new(data['user']) if data['user']
        @language = data['language']
      end
    end
    
    class Message < BaseType
      attr_reader :message_id, :from, :chat, :date, :text, :entities,
                  :reply_markup, :via_bot, :forward_from, :forward_from_chat
      
      def initialize(data)
        super(data)
        
        @message_id = data['message_id']
        @from = User.new(data['from']) if data['from']
        @chat = Chat.new(data['chat']) if data['chat']
        @date = Time.at(data['date']) if data['date']
        @text = data['text']
        
        if data['entities']
          @entities = data['entities'].map { |e| MessageEntity.new(e) }
        end
        
        @reply_markup = data['reply_markup']
        @via_bot = User.new(data['via_bot']) if data['via_bot']
        @forward_from = User.new(data['forward_from']) if data['forward_from']
        @forward_from_chat = Chat.new(data['forward_from_chat']) if data['forward_from_chat']
      end
      
      # FIXED: Proper command detection
      def command?
        return false unless text
        return false unless entities
        
        # Find a "bot_command" entity
        command_entity = entities.find { |e| e.type == 'bot_command' }
        return false unless command_entity
        
        # Extract the command text
        command_text = text[command_entity.offset, command_entity.length]
        command_text&.start_with?('/')
      end
      
      def command_name
        return nil unless command?
        
        command_entity = entities.find { |e| e.type == 'bot_command' }
        return nil unless command_entity
        
        cmd = text[command_entity.offset, command_entity.length]
        cmd = cmd[1..-1]  # Remove "/"
        cmd = cmd.split('@').first  # Remove bot username
        cmd
      end
      
      def command_args
        return nil unless command?
        
        command_entity = entities.find { |e| e.type == 'bot_command' }
        return nil unless command_entity
        
        # Text after the command entity
        args_start = command_entity.offset + command_entity.length
        text[args_start..-1]&.strip
      end
    end
    
    class CallbackQuery < BaseType
      attr_reader :id, :from, :message, :data, :chat_instance
      
      def initialize(data)
        super(data)
        
        @id = data['id']
        @from = User.new(data['from']) if data['from']
        @message = Message.new(data['message']) if data['message']
        @data = data['data']
        @chat_instance = data['chat_instance']
      end
    end
    
    class Update < BaseType
      attr_reader :update_id, :message, :callback_query
      
      def initialize(data)
        super(data)
        
        @update_id = data['update_id']
        @message = Message.new(data['message']) if data['message']
        @callback_query = CallbackQuery.new(data['callback_query']) if data['callback_query']
      end
    end
  end
end
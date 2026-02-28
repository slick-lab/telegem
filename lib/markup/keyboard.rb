module Telegem
  module Markup

    module ReplyButtons
      def text(content, style: nil, icon_custom_emoji_id: nil)
        {
          text: content,
          icon_custom_emoji_id: icon_custom_emoji_id,
          style: style
      }.compact
    end
    def request_contact(text, style: nil, icon_custom_emoji_id: nil)
      {
        text: text,
        style: style,
        icon_custom_emoji_id: icon_custom_emoji_id,
        request_contact: true
    }.compact
    end
    def request_location(text, style: nil, icon_custom_emoji_id:  nil)
      {
        text: text,
        style: style,
        icon_custom_emoji_id: icon_custom_emoji_id,
        request_location: true
    }.compact
  end 
  def request_poll(text, poll_type: nil, style: nil, icon_custom_emoji_id: nil)
    {
      text: text,
      style: style,
      icon_custom_emoji_id: icon_custom_emoji_id,
      request_poll: poll_type ? { type: poll_type } : {}
    }.compact
  end
  def web_app(text, url: nil, style: nil, icon_custom_emoji_id: nil)
    {
      text: text,
      url: url,
      style: style,
      icon_custom_emoji_id: icon_custom_emoji_id
    }.compact
  end
end
    class ReplyBuilder
      include ReplyButtons
      def initialize
        @rows = []
        @options = {
          resize_keyboard: true,
          one_time_keyboard: false,
          selective: false
        }
      end
      def row(*buttons)
        @rows << buttons
        self
      end
      def resize(value = true)
        @options[:resize_keyboard] = value
        self
      end
      def one_time(value = true)
        @options[:one_time_keyboard] = value
        self
      end
      def selective(value = true)
        @options[:selective] = value
        self
      end
      def placeholder(text)
        @options[:input_field_placeholder] = text
        self
      end
      def build
        ReplyKeyboard.new(@rows, @options)
    end
  end 
      class ReplyKeyboard
        def initialize(rows, options = {})
          @rows = rows
          @options = options
        end
        def to_h
          {
            keyboard: @rows
        }.merge(@options)
        end
        def to_json(*args)
          to_h.to_json(*args)
        end 
      end 
      def self.keyboard(&block)
        builder = ReplyBuilder.new
        builder.instance_eval(&block) if block_given?
        builder.build
      end 
    end 
  end 
    
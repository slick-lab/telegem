module Telegem
  module Markup

    module InlineButtons
      def callback(text, data, style: nil, icon_custom_emoji_id: nil)
       {
        text: text,
        callback_data: data,
        style: style,
        icon_custom_emoji_id: icon_custom_emoji_id
      }.compact
    end 
    def url(text, url, style: nil, icon_custom_emoji_id: nil)
      {
        text: text,
        url: url,
        style: style,
        icon_custom_emoji_id: icon_custom_emoji_id
      }.compact
    end
    def switch_inline(text, query: nil, style: nil, icon_custom_emoji_id: nil)
      {
        text: text,
        switch_inline_query: query,
        style: style,
        icon_custom_emoji_id: icon_custom_emoji_id
      }.compact
    end
    def switch_inline_current_chat(text, query: nil, style: nil, icon_custom_emoji_id: nil)
      {
        text: text,
        switch_inline_query_current_chat: query,
        style: style,
        icon_custom_emoji_id: icon_custom_emoji_id
      }.compact
    end
    def callback_game(text, game_short_name, style: nil, icon_custom_emoji_id: nil)
      {
        text: text,
        callback_game: { short_name: game_short_name },
        style: style,
        icon_custom_emoji_id: icon_custom_emoji_id
      }.compact
    end
    def pay(text, style: nil, icon_custom_emoji_id: nil)
      {
        text: text,
        pay: true,
        style: style,
        icon_custom_emoji_id: icon_custom_emoji_id
      }.compact
    end
    def web_app(text, url: nil, style: nil, icon_custom_emoji_id: nil)
      {
        text: text,
        web_app: { url: url },
        style: style,
        icon_custom_emoji_id: icon_custom_emoji_id
      }.compact
    end
    def login(text, url, style: nil, icon_custom_emoji_id: nil, **options)
      login_url = { url: url}.merge(options)
      {
        text: text,
        login_url: login_url,
        style: style,
        icon_custom_emoji_id: icon_custom_emoji_id
    }.compact
  end 
end
   class InlineBuilder
      include InlineButtons
      def initialize
        @rows = []
      end
      def row(*buttons)
        @rows << buttons
        self
      end
      def build
        InlineKeyboard.new(@rows)
    end
  end 
      class InlineKeyboard
        attr_reader :rows
        def initialize(rows)
          @rows = rows
        end
        def to_h
          {
            inline_keyboard: @rows
          }
        end
        def to_json(*args)
          to_h.to_json(*args)
        end
      end 
      def self.inline(&block)
        builder = InlineBuilder.new
        builder.instance_eval(&block) if block_given?
        builder.build
      end
    end
  end 

module Telegem
  module Markup
    class Keyboard
      attr_reader :buttons, :options

      def initialize(buttons = [], **options)
        @buttons = buttons
        @options = {
          resize_keyboard: true,
          one_time_keyboard: false,
          selective: false
        }.merge(options)
      end

      def self.[](*rows)
        new(rows)
      end

      def self.build(&block)
        builder = Builder.new
        builder.instance_eval(&block) if block_given?
        builder.keyboard
      end

      def row(*buttons)
        @buttons << buttons.flatten
        self
      end

      def button(text, **options)
        if @buttons.empty? || !@buttons.last.is_a?(Array)
          @buttons << [{ text: text }.merge(options)]
        else
          @buttons.last << { text: text }.merge(options)
        end
        self
      end

      def request_contact(text)
        button(text, request_contact: true)
      end

      def request_location(text)
        button(text, request_location: true)
      end

      def request_poll(text, type = nil)
        opts = type ? { request_poll: { type: type } } : { request_poll: {} }
        button(text, opts)
      end

      def resize(resize = true)
        @options[:resize_keyboard] = resize
        self
      end

      def one_time(one_time = true)
        @options[:one_time_keyboard] = one_time
        self
      end

      def selective(selective = true)
        @options[:selective] = selective
        self
      end

      def to_h
        {
          keyboard: @buttons.map { |row| row.is_a?(Array) ? row : [row] },
          **@options
        }
      end

      def to_json(*args)
        to_h.to_json(*args)
      end

      def self.remove(selective: false)
        {
          remove_keyboard: true,
          selective: selective
        }
      end

      def self.force_reply(selective: false, input_field_placeholder: nil)
        markup = {
          force_reply: true,
          selective: selective
        }
        markup[:input_field_placeholder] = input_field_placeholder if input_field_placeholder
        markup
      end
    end

    class InlineKeyboard
      attr_reader :buttons

      def initialize(buttons = [])
        @buttons = buttons
      end

      def self.[](*rows)
        new(rows)
      end

      def self.build(&block)
        builder = InlineBuilder.new
        builder.instance_eval(&block) if block_given?
        builder.keyboard
      end

      def row(*buttons)
        @buttons << buttons.flatten
        self
      end

      def button(text, **options)
        if @buttons.empty? || !@buttons.last.is_a?(Array)
          @buttons << [{ text: text }.merge(options)]
        else
          @buttons.last << { text: text }.merge(options)
        end
        self
      end

      def url(text, url)
        button(text, url: url)
      end

      def callback(text, data)
        button(text, callback_data: data)
      end

      def web_app(text, url)
        button(text, web_app: { url: url })
      end

      def login(text, url, **options)
        button(text, login_url: { url: url, **options })
      end

      def switch_inline(text, query = "")
        button(text, switch_inline_query: query)
      end

      def switch_inline_current(text, query = "")
        button(text, switch_inline_query_current_chat: query)
      end

      def pay(text)
        button(text, pay: true)
      end

      def to_h
        clean_rows = @buttons.compact.map do |row| 
          row = Array(row).compact.select { |btn| .is_a?(Hash) }
          row.empty? ? nil : row 
        end.compact 
         { inline_keyboard: clean_rows} 
      end 
   end 
      def to_json(*args)
        to_h.to_json(*args)
      end
    end

    class Builder
      attr_reader :keyboard

      def initialize
        @keyboard = Keyboard.new
      end

      def row(*buttons, &block)
        if block_given?
          sub_builder = Builder.new
          sub_builder.instance_eval(&block)
          @keyboard.row(*sub_builder.keyboard.buttons.flatten(1))
        elsif buttons.any?
          @keyboard.row(*buttons)
        else
          @keyboard.row
        end
        self
      end

      def button(text, **options)
        @keyboard.button(text, **options)
        self
      end

      def request_contact(text)
        @keyboard.request_contact(text)
        self
      end

      def request_location(text)
        @keyboard.request_location(text)
        self
      end

      def request_poll(text, type = nil)
        @keyboard.request_poll(text, type)
        self
      end

      def method_missing(name, *args, &block)
        if @keyboard && @keyboard.respond_to?(name)
          @keyboard.send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, include_private = false)
        @keyboard && @keyboard.respond_to?(name) || super
      end
    end

    class InlineBuilder
      attr_reader :keyboard

      def initialize
        @keyboard = InlineKeyboard.new
      end

      def row(*buttons, &block)
        if block_given?
          sub_builder = InlineBuilder.new
          sub_builder.instance_eval(&block)
          @keyboard.row(*sub_builder.keyboard.buttons.flatten(1))
        elsif buttons.any?
          @keyboard.row(*buttons)
        else
          @keyboard.row([]) 
        end
        self
      end

      def button(text, **options)
        @keyboard.button(text, **options)
        self
      end

      def url(text, url)
        @keyboard.url(text, url)
        self
      end

      def callback(text, data)
        @keyboard.callback(text, data)
        self
      end

      def web_app(text, url)
        @keyboard.web_app(text, url)
        self
      end

      def login(text, url, **options)
        @keyboard.login(text, url, **options)
        self
      end

      def switch_inline(text, query = "")
        @keyboard.switch_inline(text, query)
        self
      end

      def switch_inline_current(text, query = "")
        @keyboard.switch_inline_current(text, query)
        self
      end

      def pay(text)
        @keyboard.pay(text)
        self
      end

      def method_missing(name, *args, &block)
        if @keyboard && @keyboard.respond_to?(name)
          @keyboard.send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, include_private = false)
        @keyboard && @keyboard.respond_to?(name) || super
      end
    end

    class << self
      def keyboard(&block)
        Keyboard.build(&block)
      end

      def inline(&block)
        InlineKeyboard.build(&block)
      end

      def remove(**options)
        Keyboard.remove(**options)
      end

      def force_reply(**options)
        Keyboard.force_reply(**options)
      end
    end
  end
end
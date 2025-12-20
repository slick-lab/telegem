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

      # Create from array
      def self.[](*rows)
        new(rows)
      end

      # Builder pattern
      def self.build(&block)
        builder = Builder.new
        builder.instance_eval(&block) if block_given?
        builder.keyboard
      end

      # Add a row
      def row(*buttons)
        @buttons << buttons.flatten
        self
      end

      # Add a button
      def button(text, **options)
        last_row = @buttons.last || []

        if last_row.is_a?(Array)
          last_row << { text: text }.merge(options)
        else
          @buttons << [{ text: text }.merge(options)]
        end
        self
      end

      # Chainable options
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

      # Convert to Telegram format
      def to_h
        {
          keyboard: @buttons.map { |row| row.is_a?(Array) ? row : [row] },
          **@options
        }
      end

      def to_json(*args)
        to_h.to_json(*args)
      end

      # Remove keyboard
      def self.remove(selective: false)
        {
          remove_keyboard: true,
          selective: selective
        }
      end

      # Force reply
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

      # Create from array
      def self.[](*rows)
        new(rows)
      end

      # Builder pattern
      def self.build(&block)
        builder = InlineBuilder.new
        builder.instance_eval(&block) if block_given?
        builder.keyboard
      end

      # Add a row
      def row(*buttons)
        @buttons << buttons.flatten
        self
      end

      # Add a button
      def button(text, **options)
        last_row = @buttons.last || []

        if last_row.is_a?(Array)
          last_row << { text: text }.merge(options)
        else
          @buttons << [{ text: text }.merge(options)]
        end
        self
      end

      # URL button
      def url(text, url)
        button(text, url: url)
      end

      # Callback button
      def callback(text, data)
        button(text, callback_data: data)
      end

      # Web app button
      def web_app(text, url)
        button(text, web_app: { url: url })
      end

      # Login button
      def login(text, url, **options)
        button(text, login_url: { url: url, **options })
      end

      # Switch inline query button
      def switch_inline(text, query = "")
        button(text, switch_inline_query: query)
      end

      # Switch inline query current chat button
      def switch_inline_current(text, query = "")
        button(text, switch_inline_query_current_chat: query)
      end

      # Convert to Telegram format
      def to_h
        {
          inline_keyboard: @buttons.map { |row| row.is_a?(Array) ? row : [row] }
        }
      end

      def to_json(*args)
        to_h.to_json(*args)
      end
    end

    # Builder DSL for keyboards
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
        else
          @keyboard.row(*buttons)
        end
        self
      end

      def button(text, **options)
        @keyboard.button(text, **options)
        self
      end

      def method_missing(name, *args, &block)
        if @keyboard.respond_to?(name)
          @keyboard.send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, include_private = false)
        @keyboard.respond_to?(name) || super
      end
    end

    # Builder DSL for inline keyboards
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
        else
          @keyboard.row(*buttons)
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

      def method_missing(name, *args, &block)
        if @keyboard.respond_to?(name)
          @keyboard.send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, include_private = false)
        @keyboard.respond_to?(name) || super
      end
    end

    # Shortcuts for common use
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
# Plugins

Telegem includes several plugins for common bot functionality. Plugins extend the bot with specialized features.

## FileExtract Plugin

Extract content from uploaded files automatically detecting file types.

### Supported Formats

- **PDF**: Text extraction with page count and metadata
- **JSON**: Full parsing of nested structures
- **HTML**: Tag stripping with title extraction
- **Text files**: Full content with line count (.txt, .md, .csv)

### Usage

```ruby
require 'telegem/plugins/file_extract'

bot.document do |ctx|
  doc = ctx.message.document
  file_id = doc.file_id

  extractor = Telegem::Plugins::FileExtract.new(ctx.bot, file_id)

  result = extractor.extract

  if result[:success]
    ctx.reply("Extracted #{result[:type]} content:")
    ctx.reply(result[:content][0..100] + "...")  # First 100 chars
  else
    ctx.reply("Extraction failed: #{result[:error]}")
  end
end
```

### Configuration Options

```ruby
extractor = Telegem::Plugins::FileExtract.new(
  bot,
  file_id,
  auto_delete: true,      # Delete temp files after processing
  max_file_size: 50_000_000,  # 50MB limit
  timeout: 60             # Processing timeout
)
```

### Result Structure

**Success Response:**
```ruby
{
  success: true,
  type: :pdf,           # :pdf, :json, :html, :text
  content: "extracted text or parsed data",
  metadata: {
    size: 12345,        # File size in bytes
    # Format-specific metadata
  }
}
```

**Error Response:**
```ruby
{
  success: false,
  error: "Error message"
}
```

### Format-Specific Metadata

**PDF:**
```ruby
metadata: {
  page_count: 10,
  info: { Creator: "PDF Creator", Producer: "PDF Producer" }
}
```

**JSON:**
```ruby
metadata: {
  size: 1024,
  keys: ["name", "age", "items"],
  length: 25  # For arrays
}
```

**HTML:**
```ruby
metadata: {
  size: 2048,
  title: "Page Title"
}
```

**Text:**
```ruby
metadata: {
  size: 512,
  line_count: 15
}
```

### Error Handling

```ruby
result = extractor.extract

case result[:error]
when "Unsupported file type"
  # Handle unsupported format
when "Failed to extract PDF"
  # Handle PDF extraction failure
when "Invalid JSON format"
  # Handle JSON parsing error
else
  # Handle other errors
end
```

### Advanced Usage

```ruby
# Process different file types differently
bot.document do |ctx|
  extractor = Telegem::Plugins::FileExtract.new(ctx.bot, ctx.message.document.file_id)
  result = extractor.extract

  case result[:type]
  when :pdf
    # Handle PDF
    page_count = result[:metadata][:page_count]
    ctx.reply("PDF has #{page_count} pages")

  when :json
    # Handle JSON
    data = result[:content]
    if data.is_a?(Hash) && data['type'] == 'config'
      # Process config file
    end

  when :text
    # Handle text
    lines = result[:content].split("\n")
    # Process lines
  end
end
```

## Translate Plugin

Translate text between languages using an external translation service.

### Usage

```ruby
require 'telegem/plugins/translate'

bot.command('translate') do |ctx|
  text = ctx.command_args
  if text
    translator = Telegem::Plugins::Translate.new(text, 'en', 'es')
    # Translation happens synchronously
    ctx.reply("Translation result would be here")
  else
    ctx.reply("Usage: /translate <text>")
  end
end
```

### Constructor

```ruby
translator = Telegem::Plugins::Translate.new(word, from_lang, to_lang)
```

**Parameters:**
- `word` (String): Text to translate
- `from_lang` (String): Source language code ('en', 'es', 'fr', etc.)
- `to_lang` (String): Target language code

### Response

**Success:**
```ruby
{
  error: "false",
  translation: "translated text"
}
```

**Error:**
```ruby
{
  error: "an error occurred",
  code: "HTTP status code"
}
```

### Integration Example

```ruby
bot.hears(/^translate (.+) to (\w+)/) do |ctx|
  text = ctx.match[1]
  target_lang = ctx.match[2]

  translator = Telegem::Plugins::Translate.new(text, 'auto', target_lang)
  result = translator.start_translating

  if result[:error] == "false"
    ctx.reply("Translation: #{result[:translation]}")
  else
    ctx.reply("Translation failed")
  end
end
```

## Creating Custom Plugins

### Plugin Structure

```ruby
module Telegem
  module Plugins
    class MyPlugin
      def initialize(bot, *args, **options)
        @bot = bot
        @options = options
        # Initialize plugin
      end

      def do_something
        # Plugin logic
      end
    end
  end
end
```

### Usage in Bot

```ruby
require 'telegem/plugins/my_plugin'

bot.command('mycommand') do |ctx|
  plugin = Telegem::Plugins::MyPlugin.new(ctx.bot, arg1, option: value)
  result = plugin.do_something
  ctx.reply(result)
end
```

### Async Plugin Example

```ruby
class AsyncPlugin
  def initialize(bot, data)
    @bot = bot
    @data = data
  end

  def process_async(&callback)
    Async do
      result = long_running_operation(@data)
      callback.call(result)
    end
  end
end

# Usage
bot.command('async') do |ctx|
  plugin = AsyncPlugin.new(ctx.bot, ctx.text)
  plugin.process_async do |result|
    ctx.reply("Result: #{result}")
  end
end
```

## Plugin Best Practices

### Error Handling

```ruby
class RobustPlugin
  def extract
    begin
      # Plugin logic
      { success: true, data: result }
    rescue => e
      { success: false, error: e.message }
    end
  end
end
```

### Configuration

```ruby
class ConfigurablePlugin
  DEFAULTS = {
    timeout: 30,
    retries: 3
  }

  def initialize(bot, **options)
    @options = DEFAULTS.merge(options)
  end
end
```

### Resource Management

```ruby
class ResourcePlugin
  def initialize(bot)
    @temp_files = []
  end

  def process
    # Create temp files
    # Process
    # Return result
  ensure
    cleanup_temp_files
  end

  private

  def cleanup_temp_files
    @temp_files.each do |file|
      File.unlink(file) rescue nil
    end
    @temp_files.clear
  end
end
```

### Logging

```ruby
class LoggingPlugin
  def initialize(bot, logger = nil)
    @logger = logger || bot.logger
  end

  def do_work
    @logger.info("Starting work")
    result = perform_work
    @logger.info("Work completed")
    result
  end
end
```

## Available Plugins Summary

| Plugin | Purpose | Dependencies |
|--------|---------|--------------|
| FileExtract | Extract content from files | pdf-reader |
| Translate | Translate text | httparty |

## Installing Plugin Dependencies

```ruby
# Gemfile
gem 'telegem'
gem 'pdf-reader'  # For FileExtract
gem 'httparty'    # For Translate
```

## Contributing Plugins

1. Create plugin in `lib/telegem/plugins/`
2. Add comprehensive documentation
3. Include tests
4. Follow naming conventions
5. Handle errors gracefully
6. Make configuration optional

Plugins extend Telegem's functionality, allowing developers to add specialized features without modifying the core framework.</content>
<parameter name="filePath">/home/slick/telegem/docs/plugins.md
# Bot Configuration

The `Telegem::Core::Bot` class is the main entry point for creating and configuring Telegram bots.

## Initialization

```ruby
bot = Telegem.new(token, **options)
```

### Parameters

- `token` (String): Your bot token from @BotFather
- `options` (Hash): Configuration options

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `logger` | Logger | STDOUT logger | Logger instance for bot output |
| `timeout` | Integer | 30 | HTTP request timeout in seconds |
| `session_store` | Store | MemoryStore | Session storage backend |

## Basic Configuration

```ruby
require 'telegem'

bot = Telegem.new(
  'YOUR_BOT_TOKEN',
  logger: Logger.new('bot.log'),
  timeout: 60,
  session_store: Telegem::Session::RedisStore.new(redis_client)
)
```

## Handler Registration

### Commands

```ruby
bot.command('start') do |ctx|
  ctx.reply("Welcome!")
end

bot.command('help') do |ctx|
  ctx.reply("Help message")
end
```

Commands automatically match `/command` or `/command@botname`.

### Text Patterns

```ruby
# Exact match
bot.hears('hello') do |ctx|
  ctx.reply("Hi there!")
end

# Regular expressions
bot.hears(/^hello/i) do |ctx|
  ctx.reply("Hello to you too!")
end

# Any text
bot.hears(/.+/) do |ctx|
  ctx.reply("You said: #{ctx.message.text}")
end
```

### Update Type Handlers

```ruby
# Callback queries
bot.callback_query do |ctx|
  # Handle button presses
end

# Inline queries
bot.inline_query do |ctx|
  # Handle inline search
end

# Media messages
bot.photo do |ctx|
  ctx.reply("Nice photo!")
end

bot.document do |ctx|
  ctx.reply("Received document")
end

# Location messages
bot.location do |ctx|
  latitude = ctx.message.location.latitude
  longitude = ctx.message.location.longitude
  ctx.reply("Location: #{latitude}, #{longitude}")
end

# Contact messages
bot.contact do |ctx|
  contact = ctx.message.contact
  ctx.reply("Contact: #{contact.first_name} #{contact.last_name}")
end
```

### Generic Handlers

```ruby
# Handle specific update types
bot.on(:message) do |ctx|
  # Handle all messages
end

bot.on(:callback_query) do |ctx|
  # Handle callback queries
end

# With filters
bot.on(:message, chat_type: 'private') do |ctx|
  # Only private messages
end

bot.on(:message, text: /^\/admin/) do |ctx|
  # Messages starting with /admin
end
```

## Middleware

```ruby
# Add middleware
bot.use(MyMiddleware.new)

# Multiple middleware
bot.use AuthenticationMiddleware.new
bot.use RateLimitMiddleware.new(limit: 10)
bot.use LoggingMiddleware.new

# Inline middleware
bot.use do |ctx, next_middleware|
  puts "Processing: #{ctx.update.type}"
  next_middleware.call(ctx)
end
```

## Scenes

```ruby
bot.scene :registration do
  step :ask_name do |ctx|
    ctx.reply("What's your name?")
  end

  step :save_name do |ctx|
    ctx.session[:name] = ctx.message.text
    ctx.reply("Hi #{ctx.session[:name]}!")
    ctx.leave_scene
  end
end

# Enter scene
bot.command('register') do |ctx|
  ctx.enter_scene(:registration)
end
```

## Error Handling

```ruby
bot.error do |error, ctx|
  puts "Error: #{error.message}"
  ctx&.reply("Sorry, something went wrong!")
end
```

## Starting the Bot

### Polling Mode (Development)

```ruby
bot.start_polling(
  timeout: 30,      # Long polling timeout
  limit: 100,       # Max updates per request
  allowed_updates: nil  # Update types to receive
)
```

### Webhook Mode (Production)

```ruby
server = bot.webhook(
  port: 3000,
  host: '0.0.0.0'
)

server.run
```

## Bot Methods

### Information

```ruby
bot.token      # Bot token
bot.api        # API client instance
bot.logger     # Logger instance
bot.running?   # Is bot running?
```

### Control

```ruby
bot.start_polling   # Start polling
bot.shutdown        # Stop bot gracefully
```

### Webhook Management

```ruby
bot.set_webhook(url: 'https://example.com/webhook')
bot.delete_webhook
bot.get_webhook_info
```

### Dynamic Handler Registration

```ruby
# Add handlers at runtime
bot.command('dynamic') do |ctx|
  ctx.reply("Dynamic command!")
end

# Remove handlers (not directly supported, recreate bot)
```

## Configuration Examples

### Development Setup

```ruby
bot = Telegem.new(
  ENV['BOT_TOKEN'],
  logger: Logger.new(STDOUT),
  session_store: Telegem::Session::MemoryStore.new
)
```

### Production Setup

```ruby
require 'redis'

redis = Redis.new(url: ENV['REDIS_URL'])
bot = Telegem.new(
  ENV['BOT_TOKEN'],
  logger: Logger.new('log/bot.log'),
  timeout: 60,
  session_store: Telegem::Session::RedisStore.new(redis)
)
```

### Custom Logger

```ruby
logger = Logger.new('bot.log')
logger.level = Logger::INFO

bot = Telegem.new(
  ENV['BOT_TOKEN'],
  logger: logger
)
```

## Edge Cases and Considerations

### Bot Token Validation

- Token must be in format: `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`
- Invalid tokens will cause API errors on first request

### Handler Conflicts

```ruby
# This will match both handlers
bot.hears(/.+/) do |ctx|
  # Matches everything
end

bot.command('start') do |ctx|
  # Never reached because regex matches first
end
```

Solution: Order matters, more specific handlers first.

### Memory Usage

- Long-running bots accumulate session data
- Use TTL on session stores
- Monitor memory usage in production

### Rate Limiting

Telegram has rate limits:

- 30 messages/second for broadcasting
- 20 callbacks/second
- Implement middleware for rate limiting

### Update Processing

- Updates are processed sequentially
- Long-running handlers block subsequent updates
- Use async operations for I/O

### Error Recovery

- Network errors cause polling retries
- Handler errors don't stop the bot
- Use error handlers for graceful degradation

## Best Practices

1. **Environment Variables**: Store tokens in environment variables
2. **Logging**: Configure appropriate log levels
3. **Error Handling**: Always implement error handlers
4. **Testing**: Test handlers with different update types
5. **Monitoring**: Monitor bot health and performance
6. **Security**: Validate inputs and use HTTPS for webhooks</content>
<parameter name="filePath">/home/slick/telegem/docs/bot.md
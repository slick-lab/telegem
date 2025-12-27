
# Bot API Reference

The `Telegem::Core::Bot` class is the main controller for your Telegram bot.

## Instantiation

```ruby
bot = Telegem.new(token, **options)
# or
bot = Telegem::Core::Bot.new(token, **options)
```

Bot Control Methods

start_polling(**options)

Starts the bot in long-polling mode (for development/local use).

```ruby
bot.start_polling(
  timeout: 30,      # Seconds to wait for updates (default: 30)
  limit: 100,       # Max updates per request (default: 100)
  allowed_updates: ['message', 'callback_query']  # Filter updates
)
```

shutdown()

Gracefully stops the bot.

```ruby
bot.shutdown  # Stops polling, closes connections, terminates workers
```

running?()

Checks if the bot is currently active.

```ruby
if bot.running?
  puts "Bot is online"
else
  puts "Bot is offline"
end
```

Handler Registration Methods

command(name, **options, &block)

Registers a command handler.

```ruby
bot.command('start') do |ctx|
  ctx.reply "Welcome! Use /help for commands."
end

# With arguments
bot.command('greet') do |ctx|
  name = ctx.command_args || 'friend'
  ctx.reply "Hello, #{name}!"
end
```

hears(pattern, **options, &block)

Registers a text pattern handler.

```ruby
# Regex pattern
bot.hears(/hello|hi|hey/i) do |ctx|
  ctx.reply "Hello there! 👋"
end

# Exact match
bot.hears('ping') do |ctx|
  ctx.reply 'pong 🏓'
end
```

on(type, filters = {}, &block)

Generic update handler.

```ruby
# Message types
bot.on(:message, photo: true) do |ctx|
  ctx.reply "Nice photo! 📸"
end

bot.on(:message, location: true) do |ctx|
  ctx.reply "Thanks for sharing your location! 📍"
end

# Callback queries (inline button clicks)
bot.on(:callback_query) do |ctx|
  ctx.answer_callback_query(text: "You clicked #{ctx.data}")
end

# Filter by chat type
bot.on(:message, chat_type: 'private') do |ctx|
  ctx.reply "This is a private chat"
end
```

Middleware System

use(middleware, *args, &block)

Adds middleware to the processing chain.

```ruby
# Built-in session middleware (auto-added)
bot.use(Telegem::Session::Middleware)

# Custom middleware
class LoggerMiddleware
  def call(ctx, next_middleware)
    puts "Processing update from #{ctx.from.id}"
    next_middleware.call(ctx)
  end
end

bot.use(LoggerMiddleware)
```

Scene System

scene(id, &block)

Defines a scene (multi-step conversation).

```ruby
bot.scene(:survey) do |scene|
  scene.step(:start) do |ctx|
    ctx.reply "What's your name?"
    ctx.session[:step] = :name
  end
  
  scene.step(:name) do |ctx|
    name = ctx.message.text
    ctx.reply "Hello #{name}! How old are you?"
    ctx.session[:name] = name
    ctx.session[:step] = :age
  end
end

# Enter scene from command
bot.command('survey') do |ctx|
  ctx.enter_scene(:survey)
end
```

Webhook Methods

webhook(**options)

Returns a webhook server instance.

```ruby
# Quick setup (auto-detects cloud platform)
server = bot.webhook.run

# Manual configuration
server = bot.webhook(
  port: 3000,
  host: '0.0.0.0',
  secret_token: ENV['SECRET_TOKEN'],
  logger: Logger.new('webhook.log')
)
server.run
server.set_webhook
```

set_webhook(url, **options)

Manually sets webhook URL.

```ruby
bot.set_webhook(
  'https://your-app.herokuapp.com/webhook',
  secret_token: 'your-secret',
  drop_pending_updates: true
)
```

delete_webhook()

Removes webhook configuration.

```ruby
bot.delete_webhook  # Switch back to polling
```

get_webhook_info()

Gets current webhook information.

```ruby
info = bot.get_webhook_info
puts "Webhook URL: #{info['url']}"
puts "Has custom certificate: #{info['has_custom_certificate']}"
```

Error Handling

error(&block)

Sets global error handler.

```ruby
bot.error do |error, ctx|
  puts "Error: #{error.message}"
  puts "Context: User #{ctx.from&.id}, Chat #{ctx.chat&.id}"
  
  # Send error to user
  ctx.reply "Something went wrong! 😅" if ctx&.chat
end
```

Update Processing

process(update_data)

Manually process an update (useful for testing).

```ruby
test_update = {
  'update_id' => 1,
  'message' => {
    'message_id' => 1,
    'from' => {'id' => 123, 'first_name' => 'Test'},
    'chat' => {'id' => 123},
    'date' => Time.now.to_i,
    'text' => '/start'
  }
}

bot.process(test_update)
```

Bot Options

Available options when creating bot:

```ruby
bot = Telegem.new('TOKEN',
  logger: Logger.new('bot.log'),      # Custom logger
  timeout: 60,                        # API timeout in seconds
  max_threads: 20,                    # Worker thread pool size
  worker_count: 5,                    # Update processing workers
  session_store: custom_store         # Custom session storage
)
```

Complete Example

```ruby
require 'telegem'

bot = Telegem.new(ENV['BOT_TOKEN'])

# Error handling
bot.error do |error, ctx|
  puts "Error: #{error.class}: #{error.message}"
end

# Commands
bot.command('start') { |ctx| ctx.reply "Welcome!" }
bot.command('help') { |ctx| ctx.reply "Available: /start, /help, /menu" }

# Interactive menu
bot.command('menu') do |ctx|
  keyboard = Telegem.keyboard do
    row "Option 1", "Option 2"
    row "Cancel"
  end
  ctx.reply "Choose:", reply_markup: keyboard
end

# Start based on environment
if ENV['RACK_ENV'] == 'production'
  bot.webhook.run
else
  bot.start_polling
end
```

---

Next: Context Methods | Keyboard API

```
```
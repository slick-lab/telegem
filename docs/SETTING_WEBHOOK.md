Webhook Setup Guide for Telegem

📖 Overview

This guide covers how to set up and run your Telegram bot using webhooks with Telegem. Webhooks are the preferred method for production bots as they provide faster response times and better reliability compared to polling.

🚀 Quick Start (For Beginners)

Basic Webhook Setup

Here's the simplest way to get your bot running with webhooks:

```ruby
# 1. Create your bot
require 'telegem'
bot = Telegem::Core::Bot.new('YOUR_BOT_TOKEN')

# 2. Add your handlers
bot.command('start') do |ctx|
  ctx.reply("Hello! I'm your bot.")
end

# 3. Start the webhook server
server = bot.webhook
server.run
```

That's it! Your bot is now:

· ✅ Listening for webhook requests
· ✅ Using the default port (3000)
· ✅ Available at /webhook/YOUR_BOT_TOKEN

Deploying to Render

For deploying to Render.com, here's your complete setup:

1. bot.rb or main.rb:

```ruby
require 'telegem'

# Initialize bot
bot = Telegem::Core::Bot.new(ENV['BOT_TOKEN'])

# Add your handlers
bot.command('start') { |ctx| ctx.reply("Hello!") }

# Start webhook server
server = bot.webhook
server.run
```

2. Gemfile:

```ruby
source 'https://rubygems.org'
gem 'telegem'
```

3. Render.com Settings:

· Start Command: bundle exec ruby bot.rb
· Environment Variables:
  · BOT_TOKEN: Your Telegram bot token
  · PORT: Automatically set by Render

⚙️ Configuration Options

Using a Configuration Block

Want to customize your webhook server? Use the block syntax:

```ruby
server = bot.webhook do |config|
  config.port = 8080                    # Custom port
  config.host = '0.0.0.0'               # Bind to all interfaces
  config.logger = MyCustomLogger.new    # Custom logger
  # No need to set endpoint - it's automatic!
end

server.run
```

Environment Variables

The server automatically reads these environment variables:

Variable Purpose Default
WEBHOOK_URL Full webhook URL for Telegram http://host:port/webhook/token
PORT Server port 3000
HOST Server host '0.0.0.0'

🔧 Advanced Configuration

Custom Webhook Path

Need a different webhook path? Here's how:

```ruby
# Method 1: Set WEBHOOK_URL environment variable
ENV['WEBHOOK_URL'] = 'https://your-domain.com/custom/path'

# Method 2: Configure Telegram manually
bot.set_webhook(
  url: 'https://your-domain.com/custom/path',
  max_connections: 40,
  allowed_updates: ['message', 'callback_query']
)
```

SSL/HTTPS Setup

For production with SSL (required by Telegram for webhooks):

```ruby
server = bot.webhook do |config|
  config.port = 443
  # SSL certificates (if running standalone)
  # config.ssl_certificate = '/path/to/cert.pem'
  # config.ssl_key = '/path/to/key.pem'
end

# Or use a reverse proxy (recommended):
# - Nginx
# - Cloudflare
# - Render's built-in HTTPS
```

Integration with Web Frameworks

Integrate Telegem into your existing Rails or Sinatra app:

```ruby
# For Rails: config/application.rb or config.ru
require 'telegem'

bot = Telegem::Core::Bot.new(ENV['BOT_TOKEN'])

# Mount as middleware in config.ru:
# use Telegem::Webhook::Middleware, bot

# For Sinatra:
require 'sinatra'
require 'telegem'

bot = Telegem::Core::Bot.new(ENV['BOT_TOKEN'])
use Telegem::Webhook::Middleware, bot

get '/' do
  "Main app is running!"
end
```

🚨 Troubleshooting

Common Issues & Solutions

1. "Undefined method `run'" Error

```ruby
# ❌ WRONG - Returns Middleware, not Server
server = bot.webhook(app: something)
server.run  # ERROR!

# ✅ CORRECT - Returns Server
server = bot.webhook  # No arguments
server.run  # WORKS!
```

2. Webhook Not Receiving Updates

```ruby
# Check if webhook is set
info = bot.get_webhook_info
puts "Webhook URL: #{info.url}"
puts "Has pending updates: #{info.pending_update_count}"

# Set webhook if needed
bot.set_webhook(url: 'https://your-domain.com/webhook/' + bot.token)
```

3. Port Already in Use

```ruby
# Use a different port
server = bot.webhook do |config|
  config.port = ENV['PORT'] || 3000  # Use Render's PORT
end
```

4. Slow Response to Telegram

```ruby
# The server responds immediately (200 OK)
# then processes updates in background threads
# This is NORMAL and by design!
```

Debug Mode

Enable detailed logging for troubleshooting:

```ruby
require 'logger'

logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG

bot = Telegem::Core::Bot.new('TOKEN', logger: logger)
server = bot.webhook do |config|
  config.logger = logger
end
```

📊 Production Best Practices

1. Health Checks

The webhook server includes a built-in health endpoint:

```
GET /health
```

Returns 200 OK - use this for monitoring.

2. Error Handling

```ruby
bot.error do |error, ctx|
  # Log to your error tracking service
  Sentry.capture_exception(error)
  
  # Optional: notify admin
  bot.api.send_message(
    chat_id: ADMIN_ID,
    text: "Bot error: #{error.message}"
  )
end
```

3. Rate Limiting

Consider adding rate limiting middleware:

```ruby
class RateLimiter
  def initialize(bot, requests_per_minute: 60)
    @bot = bot
    @limits = {}
  end
  
  def call(ctx)
    user_id = ctx.from.id
    # Implement your rate limiting logic
    # ...
    yield  # Continue to next middleware/handler
  end
end

bot.use RateLimiter
```

4. Monitoring

Monitor these key metrics:

· Response time to Telegram (< 1 second)
· Error rate (< 1%)
· Queue length (pending updates)

🔄 Webhook vs Polling

Aspect Webhook Polling
Performance Faster (real-time) Slower (up to 30s delay)
Resource Use Efficient Constant requests
Setup More complex Simple
Production ✅ Recommended Only for dev/testing
Render.com Web Service Background Worker

```ruby
# Switching between methods is easy:
if ENV['RACK_ENV'] == 'production'
  # Use webhooks in production
  bot.webhook.run
else
  # Use polling in development
  bot.start_polling
  sleep  # Keep process alive
end
```

🎯 Example: Complete Production Setup

```ruby
# production_bot.rb
require 'telegem'
require 'logger'

# Configure bot
bot = Telegem::Core::Bot.new(
  ENV['BOT_TOKEN'],
  logger: Logger.new('logs/bot.log', 'daily')
)

# Add middleware
bot.use MyAuthMiddleware
bot.use RateLimiter

# Add handlers
bot.command('start') { |ctx| ctx.reply("Welcome!") }
# ... more handlers

# Error handling
bot.error do |error, ctx|
  logger.error("Error: #{error.message}")
  ctx&.reply("Sorry, something went wrong!")
end

# Get Render's port or use default
port = ENV['PORT'] || 3000

# Start server
server = bot.webhook do |config|
  config.port = port
  config.host = '0.0.0.0'
end

puts "🚀 Starting bot on port #{port}"
puts "📡 Webhook URL: #{server.webhook_url}"
server.run
```

❓ FAQ

Q: What port should I use?
A: Use ENV['PORT'] on Render/Heroku, or 3000 for local development.

Q: Do I need to call set_webhook?
A: Not with Telegem! It sets the webhook automatically when you call server.webhook_url.

Q: Can I run multiple bots?
A: Yes! Each needs its own server instance on a different port.

Q: How do I handle bot restarts?
A: The server gracefully shuts down on SIGTERM. Set restart: always in your deployment config.

Q: My bot stops after some time?
A: On Render's free tier, services sleep after inactivity. Upgrade to a paid plan for 24/7 uptime.

📚 Additional Resources

· Telegram Bot API Documentation
· Render.com Deployment Guide
· Telegem GitHub Repository
· Webhook vs Polling Explained

---

Need Help?

· Check the server logs: tail -f logs/bot.log
· Verify webhook URL with bot.get_webhook_info
· Test locally with ngrok: ngrok http 3000

Happy bot building! 🤖
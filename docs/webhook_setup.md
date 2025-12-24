
# 🌐 Webhook Setup Guide for Telegem

Webhooks are the **recommended way** to run your Telegram bot in production. Instead of your bot constantly asking Telegram for updates ("polling"), Telegram pushes updates directly to your bot's server.

**Join the official channel for help and updates!** [![Official Telegem Channel](https://img.shields.io/badge/🚀-t.me/telegem__me2-blue?style=flat&logo=telegram)](https://t.me/telegem_me2)

## 🤔 Polling vs. Webhook: A Quick Analogy
*   **Polling** is like refreshing your email every 5 seconds to check for new messages. It works, but it's inefficient.
*   **Webhook** is like giving Telegram your email address and saying, "Send new messages directly to my inbox as they arrive." It's instant, efficient, and scales beautifully.

## 🚀 Quick-Start: One-Line Webhook Setup

The easiest way to get a production webhook server running is with our `webhook` helper. It handles **everything**: starting the server, getting your public URL, and configuring Telegram.

```ruby
require 'telegem'

bot = Telegem.new("YOUR_BOT_TOKEN")

bot.on(:message) do |ctx|
  ctx.reply("Hello from my webhook-powered bot! 🚀")
end

# This single line does the magic:
# 1. Starts a production Puma web server
# 2. Configures a secure webhook endpoint
# 3. Tells Telegram where to send updates
server = Telegem.webhook(bot)
```

That's it! Your bot is now live with a webhook. The server runs in the background until you call server.stop.

🔧 Understanding the Setup (How it Works)

Let's break down what the helper does. Here's the equivalent manual setup:

```ruby
require 'telegem'

bot = Telegem.new("YOUR_BOT_TOKEN")
bot.on(:message) { |ctx| ctx.reply("Manual setup works!") }

# 1. Create a webhook server instance
server = bot.webhook(port: 3000) # Uses PORT env variable on cloud platforms

# 2. Start the server (listens for incoming requests)
server.run

# 3. Tell Telegram your webhook URL with a secret token
server.set_webhook
```

What's happening behind the scenes?

1. Server Creation: Telegem creates a secure, production-ready Puma web server.
2. Endpoint Setup: It creates a /webhook endpoint that validates incoming requests using a secret_token (for security).
3. Cloud Detection: It automatically detects if you're running on Render, Railway, Heroku, Fly.io, or Vercel and configures the public URL accordingly.
4. Telegram Configuration: The set_webhook method registers your bot's public URL with Telegram's servers.

☁️ Deployment to Cloud Platforms

Telegem's webhook server is optimized for modern cloud platforms. Here's how to deploy:

Option A: Deploy to Render (Free Tier Friendly)

1. Create these files in your project:
   bot.rb
   ```ruby
   require 'telegem'
   
   bot = Telegem.new(ENV['TELEGRAM_BOT_TOKEN'])
   
   bot.command("start") { |ctx| ctx.reply("Bot is live on Render! ☁️") }
   bot.on(:message) { |ctx| ctx.reply("You said: #{ctx.message.text}") }
   
   # This auto-starts the webhook server in production
   Telegem.webhook(bot) if ENV['RACK_ENV'] == 'production'
   ```
   Gemfile
   ```ruby
   source 'https://rubygems.org'
   gem 'telegem'
   ```
   config.ru (required for Render to recognize it as a web service)
   ```ruby
   require './bot'
   # The server is started by Telegem.webhook
   run ->(env) { [200, {}, ['Telegem Bot Server']] }
   ```
2. Push to GitLab/GitHub.
3. On Render.com:
   · Click "New +" → "Web Service"
   · Connect your repository
   · Set the following:
     · Name: telegem-bot (or your choice)
     · Environment: Ruby
     · Build Command: bundle install
     · Start Command: bundle exec puma -p $PORT
   · Click "Advanced" and add an Environment Variable:
     · Key: TELEGRAM_BOT_TOKEN
     · Value: Your bot token from @BotFather
4. Click "Create Web Service". Your bot will build, deploy, and automatically configure its webhook!

Option B: Deploy with Existing Rack Apps (Rails, Sinatra, etc.)

If you already have a Rack application, use the Telegem Middleware:

```ruby
# In your config.ru (or similar)
require 'telegem'
require './your_main_app'

bot = Telegem.new(ENV['TELEGRAM_BOT_TOKEN'])
bot.on(:message) { |ctx| ctx.reply("Hello from middleware!") }

# Insert the middleware into your app's stack
use Telegem::Webhook::Middleware, bot, secret_token: ENV['TELEGRAM_SECRET_TOKEN']

run YourApp
```

Then, set the webhook URL manually:

```ruby
# Run this once (e.g., in a script or console)
bot.set_webhook(
  url: "https://your-app.com/webhook",
  secret_token: ENV['TELEGRAM_SECRET_TOKEN']
)
```

🔐 Security & Configuration

Secret Token: Your Webhook's Bouncer

The secret_token is a password that ensures only Telegram can talk to your webhook. Telegram sends it in the X-Telegram-Bot-Api-Secret-Token header with every request.

· Generate a strong one: Use SecureRandom.hex(32).
· Set it in production: Pass it when creating the server or via the TELEGRAM_SECRET_TOKEN environment variable.
· Never commit it to git!

Manual Webhook Management

Use these methods for fine-grained control:

```ruby
# Check your current webhook status
info = bot.get_webhook_info
puts info.url # => "https://your-app.com/webhook"

# Delete the webhook (switch back to polling)
bot.delete_webhook

# Set a custom webhook with specific options
bot.set_webhook(
  url: "https://api.example.com/custom-path",
  secret_token: "your_super_secret_token_here",
  max_connections: 40,
  allowed_updates: ["message", "callback_query"], # Only receive these updates
  drop_pending_updates: true # Clears old updates when setting
)
```

🚨 Common Issues & Troubleshooting

· "My bot works locally but not on Render!"
  · Check the Render logs for errors.
  · Ensure the TELEGRAM_BOT_TOKEN environment variable is set correctly in Render's dashboard.
  · Verify your bot's code doesn't have any syntax errors by running ruby bot.rb locally.
· "I'm getting duplicate messages or missed updates!"
  · You likely have both polling and webhook active. Call bot.delete_webhook if you used start_polling before, or ensure you're not accidentally running start_polling in your webhook deployment.
· "How do I update my bot's code?"
  · Simply push your changes to git. Your cloud platform (like Render) will automatically rebuild and redeploy. The webhook URL stays the same, so no reconfiguration is needed.
· "I need to stop the webhook server."
  · Call server.stop on the server object, or send a SIGTERM signal to the process.

🧪 Testing Webhooks Locally

For local development, you can still use polling. But if you want to test the webhook flow:

1. Use a tunneling service like ngrok:
   ```bash
   ngrok http 3000
   ```
2. Copy the HTTPS URL ngrok provides (e.g., https://abc123.ngrok.io).
3. Set your webhook manually:
   ```ruby
   bot.set_webhook(url: "https://abc123.ngrok.io/webhook")
   ```
4. Telegram will now send updates to your local machine through the tunnel!

---

Pro Tip: The one-liner Telegem.webhook(bot) is perfect for 95% of use cases. It embodies the Telegem philosophy: powerful functionality with a simple, elegant API.

For more help and community discussion, remember to join our official channel: https://img.shields.io/badge/💬-Join_t.me/telegem__me2-blue?style=flat&logo=telegram.

Happy Building! The future of your Telegram bot is just a webhook away. 🚀

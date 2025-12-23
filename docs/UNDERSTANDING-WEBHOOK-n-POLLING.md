📡 Setting Up Webhooks - Complete Beginner's Guide

Webhooks sound complicated, but they're actually simple. Let me explain with an analogy:

🍕 The Pizza Delivery Analogy

Polling (The Old Way)

You call the pizza shop every minute: "Is my pizza ready yet? No? OK, I'll call again in a minute..."

Code: bot.start_polling() - Your bot calls Telegram every second asking for new messages.

Webhooks (The Smart Way)

You give the pizza shop your address. When pizza is ready, they deliver it to you.

Code: bot.set_webhook(url) - You give Telegram your server's address. When there's a message, they send it to you.

🚀 Quick Examples

Example 1: Polling (Easiest for Beginners)

```ruby
require 'telegem'

bot = Telegem.new('YOUR_TOKEN')

bot.command('start') do |ctx|
  ctx.reply("Hello! I'm using polling 🍕")
end

# Just ONE line - that's it!
bot.start_polling
```

Run it:

```bash
ruby bot.rb
# Bot starts checking for messages every second
```

Example 2: Webhook (For Production)

```ruby
require 'telegem'

bot = Telegem.new('YOUR_TOKEN')

bot.command('start') do |ctx|
  ctx.reply("Hello! I'm using webhooks 🚚")
end

# Step 1: Start your "delivery address" (server)
server = bot.webhook(port: 3000)
server.run

# Step 2: Tell Telegram your address
bot.set_webhook!("https://your-domain.com/webhook/#{bot.token}")
```

Run it:

```bash
ruby bot.rb
# Bot waits for Telegram to deliver messages
```

🔄 Hot-Swap Between Polling & Webhooks

Here's how to switch while your bot is running:

```ruby
require 'telegem'

bot = Telegem.new('YOUR_TOKEN')

bot.command('mode') do |ctx|
  ctx.reply("Use /polling or /webhook to switch modes")
end

bot.command('polling') do |ctx|
  # Switch TO polling
  bot.shutdown           # Stop current mode
  bot.start_polling      # Start polling
  ctx.reply("✅ Switched to polling mode")
end

bot.command('webhook') do |ctx|
  # Switch TO webhook
  bot.shutdown           # Stop current mode
  
  server = bot.webhook(port: 3000)
  server.run
  
  # For demo, use ngrok URL (get yours at ngrok.com)
  bot.set_webhook!("https://abc123.ngrok.io/webhook/#{bot.token}")
  
  ctx.reply("✅ Switched to webhook mode")
end

# Start with polling by default
bot.start_polling
```

📊 Polling vs Webhooks: Side-by-Side Comparison

 |Polling 🍕| Webhooks 🚚 |
 | ------- | ------- |
 | Bot asks Telegram: "New messages?" | Telegram sends messages to bot |
 | Setup bot.start_polling() | Server + set_webhook() |
 | Best for Development, testing  | Production, high traffic | 
| Speed Up to 1-second delay | Instant delivery |
| SSL Required? ❌ No | ✅ Yes (Telegram requires HTTPS) |
| Server Needed? ❌ No | ✅ Yes | 
| Battery/CPU ⚠️ Uses more (always checking) | ✅ Efficient (sleeps until delivery) |
| Can Switch? ✅ Yes (hot-swap) | ✅ Yes (hot-swap) |

🎯 When to Use Which?

Use Polling When:

· 👶 You're learning - Keep it simple
· 💻 Developing locally - No server setup needed
· 🧪 Testing new features - Quick restarts
· 📱 Running on your laptop - No public URL needed

Use Webhooks When:

· 🚀 Going to production - Better performance
· 📈 Expecting many users - Handles traffic better
· ☁️ Hosting on a server - You have a public URL
· 🔋 Saving resources - Uses less CPU/battery

🔧 Webhook Setup for Beginners

Step 1: Get a Public URL (Development)

For development, use ngrok (free):

```bash
# Install ngrok, then run:
ngrok http 3000
```

You'll get a URL like: https://abc123.ngrok.io

Step 2: Simple Webhook Bot

```ruby
# webhook_bot.rb
require 'telegem'

bot = Telegem.new('YOUR_TOKEN')

bot.command('start') do |ctx|
  ctx.reply("I'm using webhooks! Try /info")
end

bot.command('info') do |ctx|
  info = bot.get_webhook_info!
  ctx.reply("Webhook info: #{info}")
end

# Start server
server = bot.webhook(port: 3000)
server.run

puts "🚀 Server running! Set webhook to:"
puts "https://YOUR_NGROK_URL.ngrok.io/webhook/#{bot.token}"
puts ""
puts "Run this command to set webhook:"
puts "bot.set_webhook!('https://YOUR_NGROK_URL.ngrok.io/webhook/#{bot.token}')"
```

Step 3: Set the Webhook

Open IRB in another terminal:

```ruby
require 'telegem'
bot = Telegem.new('YOUR_TOKEN')
bot.set_webhook!('https://abc123.ngrok.io/webhook/YOUR_TOKEN')
# => true (means success!)
```

❓ Common Questions

"Do I need to keep my computer on?"

· Polling: ❌ Yes, bot must keep asking
· Webhook: ✅ No, your SERVER needs to be on

"Can I use webhook without a server?"

No, you need somewhere for Telegram to deliver messages. But many free options:

· Railway (free tier) - railway.app
· Render (free tier) - render.com
· Heroku (free tier) - heroku.com

"Which is faster?"

Webhooks! Messages arrive instantly instead of up to 1-second delay.

🎮 Try It Yourself Exercise

Create mode_demo.rb:

```ruby
require 'telegem'

bot = Telegem.new('YOUR_TOKEN')

bot.command('help') do |ctx|
  ctx.reply(<<~TEXT
    🤖 Mode Demo Bot
    
    /polling - Switch to polling mode
    /webhook - Switch to webhook mode  
    /current - Show current mode
    /test - Send test message
  TEXT
  )
end

# Start in polling mode (easiest)
bot.start_polling
puts "Bot started in polling mode. Try /help"
```

Run it and try switching modes while the bot is running!

📚 Remember This:

· Start with polling - It's easier
· Switch to webhooks when going to production
· You can always switch back - It's not permanent
· Your bot code stays the same - Only the delivery method changes

Happy bot building! 🎉
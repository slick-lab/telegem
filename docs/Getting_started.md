
# 🚀 Getting Started with Telegem

Welcome to Telegem! This guide will help you build your first Telegram bot in minutes.

## 📦 Installation

Add to your `Gemfile`:
```ruby
gem 'telegem'
```

Or install directly:

```bash
gem install telegem
```

🤖 Create Your First Bot

1. Get a Bot Token

1. Open Telegram, search for @BotFather
2. Send /newbot and follow instructions
3. Copy the token (looks like: 1234567890:ABCdefGHIjklMNOpqrsTUVwxyz)

2. Basic Bot Setup

```ruby
require 'telegem'

# Create bot instance
bot = Telegem.new("YOUR_BOT_TOKEN")

# Echo bot - replies with same message
bot.on(:message) do |ctx|
  ctx.reply("You said: #{ctx.message.text}")
end

# Start polling (for development)
bot.start_polling
```

Save as bot.rb and run:

```bash
ruby bot.rb
```

📝 Core Concepts

Context (ctx)

Every handler receives a Context object with everything you need:

```ruby
bot.on(:message) do |ctx|
  ctx.reply("Hello!")           # Send message
  ctx.chat.id                   # Chat ID: 123456789
  ctx.from.username             # User: @username
  ctx.message.text              # Message text
  ctx.message.command?          # Is it a command?
  ctx.message.command_name      # Command without "/"
end
```

Message Types

```ruby
# Handle different update types
bot.on(:message) { |ctx| }          # Messages
bot.on(:callback_query) { |ctx| }   # Button clicks
bot.on(:inline_query) { |ctx| }     # Inline queries
```

🎯 Common Patterns

1. Command Handler

```ruby
bot.command("start") do |ctx|
  ctx.reply("Welcome! Use /help to see commands.")
end

bot.command("help") do |ctx|
  help_text = <<~TEXT
    Available commands:
    /start - Start bot
    /help - Show this help
    /echo [text] - Echo text
  TEXT
  ctx.reply(help_text)
end
```

2. Text Matching

```ruby
# Regex pattern
bot.hears(/hello|hi|hey/i) do |ctx|
  ctx.reply("Hello there! 👋")
end

# String contains
bot.on(:message, text: "ping") do |ctx|
  ctx.reply("pong! 🏓")
end
```

3. Send Media

```ruby
bot.command("photo") do |ctx|
  ctx.photo("path/to/image.jpg", caption: "Nice pic!")
end

bot.command("document") do |ctx|
  ctx.document("file.pdf", caption: "Here's your PDF")
end
```

⌨️ Keyboards

Reply Keyboard (Shown below input)

```ruby
bot.command("menu") do |ctx|
  keyboard = Telegem.keyboard do
    row "Option 1", "Option 2"
    row "Cancel"
    resize true  # Fit to screen
  end
  
  ctx.reply("Choose option:", reply_markup: keyboard)
end
```

Inline Keyboard (Inside message)

```ruby
bot.command("settings") do |ctx|
  inline = Telegem.inline do
    row do
      callback "Enable", "enable"
      callback "Disable", "disable"
    end
    row do
      url "Documentation", "https://gitlab.com/ruby-telegem/telegem"
    end
  end
  
  ctx.reply("Settings:", reply_markup: inline)
end

# Handle button clicks
bot.on(:callback_query) do |ctx|
  if ctx.data == "enable"
    ctx.answer_callback_query(text: "Enabled!")
    ctx.edit_message_text("✅ Settings enabled!")
  end
end
```

🎭 Scene System (Multi-step Conversations)

```ruby
# Define a scene
bot.scene("registration") do
  step :ask_name do |ctx|
    ctx.reply("What's your name?")
    next_step :ask_age
  end
  
  step :ask_age do |ctx|
    ctx.state[:name] = ctx.message.text
    ctx.reply("How old are you?")
    next_step :confirm
  end
  
  step :confirm do |ctx|
    ctx.state[:age] = ctx.message.text
    ctx.reply("Confirm: Name: #{ctx.state[:name]}, Age: #{ctx.state[:age]}")
    keyboard = Telegem.inline do
      row do
        callback "✅ Confirm", "confirm_registration"
        callback "❌ Cancel", "cancel_registration"
      end
    end
    ctx.reply("Is this correct?", reply_markup: keyboard)
  end
  
  on_enter do |ctx|
    ctx.reply("Starting registration...")
  end
end

# Start the scene
bot.command("register") do |ctx|
  ctx.enter_scene("registration")
end
```

🔧 Middleware (Global Handlers)

```ruby
# Log all updates
bot.use do |ctx, next_handler|
  puts "📩 Update from #{ctx.from.username}: #{ctx.message&.text}"
  next_handler.call(ctx)
end

# Authentication middleware
class AuthMiddleware
  def initialize(allowed_users)
    @allowed_users = allowed_users
  end
  
  def call(ctx, next_handler)
    if @allowed_users.include?(ctx.from.id)
      next_handler.call(ctx)
    else
      ctx.reply("🚫 Access denied!")
    end
  end
end

bot.use(AuthMiddleware.new([123456789]))
```

💾 Session Management

```ruby
# Enable sessions (auto-saves user data)
bot.command("counter") do |ctx|
  ctx.session[:count] ||= 0
  ctx.session[:count] += 1
  ctx.reply("Count: #{ctx.session[:count]}")
end

# Persistent across bot restarts
bot.command("remember") do |ctx|
  ctx.session[:name] = ctx.message.text
  ctx.reply("I'll remember that!")
end

bot.command("recall") do |ctx|
  name = ctx.session[:name] || "I don't know your name"
  ctx.reply("Your name is: #{name}")
end
```

☁️ Webhook Setup (Production)

For Cloud Platforms (Render, Railway, Heroku):

```ruby
# In config.ru or similar
require 'telegem'

bot = Telegem.new("YOUR_TOKEN")
bot.on(:message) { |ctx| ctx.reply("Hello from webhook!") }

# Auto-starts server and sets webhook
server = Telegem.webhook(bot)

# Or manually:
# server = bot.webhook
# server.run
# server.set_webhook
```

Environment Variables:

```bash
export TELEGRAM_BOT_TOKEN="your_token"
export PORT="3000"  # Cloud platforms set this
```

🚀 Deployment Quick Start

1. Create bot.rb:

```ruby
require 'telegem'

bot = Telegem.new(ENV['TELEGRAM_BOT_TOKEN'])

bot.command("start") { |ctx| ctx.reply("Bot is running! 🚀") }
bot.on(:message) { |ctx| ctx.reply("Echo: #{ctx.message.text}") }

# For webhook (production)
if ENV['RACK_ENV'] == 'production'
  Telegem.webhook(bot)
else
  # For local development
  bot.start_polling
end
```

2. Create Gemfile:

```ruby
source 'https://rubygems.org'
gem 'telegem'
```

3. Create config.ru (for webhook):

```ruby
require './bot'
run ->(env) { [200, {}, ['']] }
```

4. Deploy to Render (Free):

1. Push to GitLab/GitHub
2. Go to render.com
3. New → Web Service → Connect repo
4. Set build command: bundle install
5. Set start command: bundle exec puma -p $PORT
6. Add env var: TELEGRAM_BOT_TOKEN=your_token
7. Deploy! 🎉

📚 Next Steps

Explore Examples:

Check the examples/ directory for:

· echo_bot.rb - Basic echo bot
· keyboard_bot.rb - Interactive keyboards
· scene_bot.rb - Multi-step conversations
· webhook_bot.rb - Production webhook setup

Need Help?

· Documentation
· Issue Tracker
· Telegram: @sick_phantom

🎉 Congratulations!

You've built your first Telegram bot with Telegem! Now go build something amazing! 🤖

---

Telegem v2.0.0 • Made with ❤️ by sick_phantom



# 🍳 Telegem Cookbook

Quick copy-paste recipes for common bot tasks. When you think "How do I...", find your answer here and just paste!

**Join for help & updates:** [![Official Channel](https://img.shields.io/badge/🚀-t.me/telegem__me2-blue?style=flat&logo=telegram)](https://t.me/telegem_me2)

---

## 📋 Table of Contents
- [Basic Setup](#-basic-setup)
- [Message Handling](#-message-handling)
- [Keyboards & Buttons](#-keyboards--buttons)
- [Files & Media](#-files--media)
- [User Management](#-user-management)
- [Scenes & Multi-step](#-scenes--multi-step)
- [Utility Patterns](#-utility-patterns)
- [Error Handling](#-error-handling)
- [Deployment](#-deployment)

---

## 🤖 Basic Setup

### Minimal Echo Bot
```ruby
require 'telegem'
bot = Telegem.new("YOUR_TOKEN")
bot.on(:message) { |ctx| ctx.reply("You said: #{ctx.message.text}") }
bot.start_polling
# Save as bot.rb and run: ruby bot.rb
```

Webhook Setup (Production)

```ruby
require 'telegem'
bot = Telegem.new(ENV['TELEGRAM_BOT_TOKEN'])
bot.on(:message) { |ctx| ctx.reply("Hello from webhook!") }
Telegem.webhook(bot) # One-liner for production
```

---

📨 Message Handling

Command with Arguments

```ruby
bot.command("search") do |ctx|
  query = ctx.message.command_args # "ruby programming" from "/search ruby programming"
  ctx.reply("Searching for: #{query}") if query
end
```

Handle Specific Text

```ruby
# Exact match
bot.on(:message, text: "ping") { |ctx| ctx.reply("pong!") }

# Regex match (case-insensitive)
bot.hears(/hello|hi|hey/i) { |ctx| ctx.reply("Greetings! 👋") }

# Contains word
bot.on(:message) do |ctx|
  if ctx.message.text&.include?("bot")
    ctx.reply("You mentioned me! 🤖")
  end
end
```

Reply to Specific Message

```ruby
bot.on(:message) do |ctx|
  # Reply to the user's message
  ctx.reply("Got it!", reply_to_message_id: ctx.message.message_id)
end
```

Different Chat Types

```ruby
bot.on(:message) do |ctx|
  case ctx.chat.type
  when "private"
    ctx.reply("Private chat 👤")
  when "group", "supergroup"
    ctx.reply("Group chat 👥")
  when "channel"
    ctx.reply("Channel 📢")
  end
end
```

---

⌨️ Keyboards & Buttons

Simple Menu Keyboard

```ruby
bot.command("menu") do |ctx|
  keyboard = Telegem.keyboard do
    row "🍕 Order Food", "🛍️ Shop"
    row "ℹ️ Help", "⚙️ Settings"
    resize true # Fits screen
    one_time true # Hides after use
  end
  ctx.reply("Main Menu:", reply_markup: keyboard)
end
```

Inline Buttons with Callback

```ruby
bot.command("vote") do |ctx|
  keyboard = Telegem.inline do
    row do
      callback "👍 Yes", "vote_yes"
      callback "👎 No", "vote_no"
    end
  end
  ctx.reply("Do you like Ruby?", reply_markup: keyboard)
end

# Handle button clicks
bot.on(:callback_query) do |ctx|
  case ctx.data
  when "vote_yes"
    ctx.answer_callback_query(text: "You voted Yes! 🎉")
    ctx.edit_message_text("✅ Thanks for voting Yes!")
  when "vote_no"
    ctx.answer_callback_query(text: "You voted No 😢", show_alert: true)
    ctx.edit_message_text("❌ You voted No")
  end
end
```

URL & Web App Buttons

```ruby
bot.command("links") do |ctx|
  keyboard = Telegem.inline do
    row do
      url "🌐 Website", "https://gitlab.com/ruby-telegem/telegem"
      url "📚 Docs", "https://core.telegram.org/bots/api"
    end
    row do
      web_app "📱 Open App", "https://yourapp.com"
    end
  end
  ctx.reply("Useful links:", reply_markup: keyboard)
end
```

Remove Keyboard

```ruby
bot.command("hide") do |ctx|
  ctx.reply("Keyboard hidden!", reply_markup: Telegem.remove_keyboard)
end
```

Request Contact/Location

```ruby
bot.command("share") do |ctx|
  keyboard = Telegem.keyboard do
    row do
      button "📱 Share Contact", request_contact: true
      button "📍 Share Location", request_location: true
    end
  end
  ctx.reply("Please share:", reply_markup: keyboard)
end

# Handle received contact
bot.on(:message) do |ctx|
  if ctx.message.contact
    phone = ctx.message.contact.phone_number
    ctx.reply("Thanks! I got your number: #{phone}")
  elsif ctx.message.location
    lat = ctx.message.location.latitude
    lon = ctx.message.location.longitude
    ctx.reply("Location received: #{lat}, #{lon}")
  end
end
```

---

📁 Files & Media

Send Photo from File

```ruby
bot.command("cat") do |ctx|
  ctx.photo("path/to/cat.jpg", caption: "Here's a cute cat! 🐱")
end
```

Send Photo from URL

```ruby
bot.command("meme") do |ctx|
  ctx.photo("https://api.memegen.com/images/buzz/memes/meme.jpg", 
            caption: "Random meme!")
end
```

Send Document

```ruby
bot.command("report") do |ctx|
  ctx.document("monthly_report.pdf", 
               caption: "Monthly Report 📊",
               filename: "report_2024.pdf") # Custom filename
end
```

Send Multiple Photos as Album

```ruby
bot.command("album") do |ctx|
  # Note: Telegram groups media with same media_group_id
  ctx.photo("photo1.jpg", caption: "First photo", media_group_id: "album_123")
  ctx.photo("photo2.jpg", caption: "Second photo", media_group_id: "album_123")
end
```

Show "Typing" Indicator

```ruby
bot.command("process") do |ctx|
  ctx.typing # Shows "typing..." for 5 seconds
  sleep 3 # Simulate work
  ctx.reply("Processing complete!")
end

# Or use the helper for longer operations
bot.command("analyze") do |ctx|
  ctx.with_typing do
    # Your processing code here
    result = complex_analysis(ctx.message.text)
    ctx.reply("Analysis: #{result}")
  end
end
```

---

👥 User Management

Welcome New Members

```ruby
bot.on(:message) do |ctx|
  if ctx.message.new_chat_members
    ctx.message.new_chat_members.each do |user|
      ctx.reply("Welcome #{user.full_name} to the group! 🎉")
    end
  end
end
```

Detect User Left

```ruby
bot.on(:message) do |ctx|
  if ctx.message.left_chat_member
    ctx.reply("#{ctx.message.left_chat_member.full_name} left the group 👋")
  end
end
```

Basic Admin Commands

```ruby
# Only works if your bot is admin
bot.command("ban") do |ctx|
  if ctx.message.reply_to_message
    user_id = ctx.message.reply_to_message.from.id
    ctx.ban_chat_member(user_id)
    ctx.reply("User banned 🚫")
  else
    ctx.reply("Reply to a message to ban the user")
  end
end

bot.command("unban") do |ctx|
  args = ctx.message.command_args
  if args && args.match?(/\d+/)
    ctx.unban_chat_member(args.to_i)
    ctx.reply("User unbanned ✅")
  end
end

bot.command("pin") do |ctx|
  if ctx.message.reply_to_message
    ctx.pin_message(ctx.message.reply_to_message.message_id)
    ctx.reply("Message pinned 📌")
  end
end
```

User Cooldown / Rate Limit

```ruby
# Using session for simple rate limiting
bot.on(:message) do |ctx|
  user_id = ctx.from.id
  last_time = ctx.session[:last_message_time] || 0
  
  if Time.now.to_i - last_time < 2 # 2 seconds cooldown
    ctx.reply("Please wait a moment... ⏳")
  else
    ctx.session[:last_message_time] = Time.now.to_i
    # Process message normally
    ctx.reply("Message received!")
  end
end
```

---

🎭 Scenes & Multi-step

Simple Registration Flow

```ruby
bot.scene("signup") do
  step :ask_name do |ctx|
    ctx.reply("What's your name?")
    next_step :ask_email
  end
  
  step :ask_email do |ctx|
    ctx.state[:name] = ctx.message.text
    ctx.reply("Great #{ctx.state[:name]}! Now enter your email:")
    next_step :confirm
  end
  
  step :confirm do |ctx|
    ctx.state[:email] = ctx.message.text
    
    keyboard = Telegem.inline do
      row do
        callback "✅ Confirm", "confirm_signup"
        callback "🔄 Restart", "restart_signup"
      end
    end
    
    ctx.reply("Confirm details:\nName: #{ctx.state[:name]}\nEmail: #{ctx.state[:email]}",
              reply_markup: keyboard)
  end
  
  on_enter do |ctx|
    ctx.reply("Starting registration... ✨")
    ctx.state.clear # Reset temp storage
  end
  
  on_leave do |ctx|
    ctx.reply("Registration complete! 🎉")
  end
end

# Start the scene
bot.command("register") { |ctx| ctx.enter_scene("signup") }

# Handle scene callbacks
bot.on(:callback_query) do |ctx|
  case ctx.data
  when "confirm_signup"
    ctx.answer_callback_query(text: "Account created!")
    # Save to database here
    ctx.leave_scene
  when "restart_signup"
    ctx.answer_callback_query(text: "Starting over...")
    ctx.enter_scene("signup") # Re-enter scene
  end
end
```

Shopping Cart Scene

```ruby
bot.scene("cart") do
  step :show_products do |ctx|
    products = ["🍎 Apple $1", "🍌 Banana $2", "🍊 Orange $3"]
    keyboard = Telegem.inline do
      products.each do |product|
        row { callback product, "add_#{product.split.first.downcase}" }
      end
      row { callback "🛒 Checkout", "checkout" }
    end
    ctx.reply("Select products:", reply_markup: keyboard)
    next_step :handle_selection
  end
  
  step :handle_selection do |ctx|
    if ctx.callback_query
      if ctx.data.start_with?("add_")
        item = ctx.data.sub("add_", "")
        ctx.session[:cart] ||= []
        ctx.session[:cart] << item
        ctx.answer_callback_query(text: "Added #{item} to cart!")
      elsif ctx.data == "checkout"
        ctx.reply("Your cart: #{ctx.session[:cart].join(', ')}")
        ctx.leave_scene
      end
    end
    # Stay in same step
    step :show_products
  end
end

bot.command("shop") { |ctx| ctx.enter_scene("cart") }
```

---

🛠️ Utility Patterns

Logging Middleware

```ruby
bot.use do |ctx, next_handler|
  puts "[#{Time.now}] #{ctx.from.username}: #{ctx.message&.text || ctx.callback_query&.data}"
  next_handler.call(ctx)
end
```

Authentication Middleware

```ruby
ADMIN_IDS = [123456789, 987654321] # Your user IDs

class AdminOnly
  def call(ctx, next_handler)
    if ADMIN_IDS.include?(ctx.from.id)
      next_handler.call(ctx)
    else
      ctx.reply("🚫 Admin only!")
    end
  end
end

bot.use(AdminOnly.new)

# Or use inline
bot.use do |ctx, next_handler|
  if ctx.from.username == "slick_phantom"
    next_handler.call(ctx)
  else
    ctx.reply("You're not slick_phantom! 🤨")
  end
end
```

User Session Data

```ruby
# Store user preferences
bot.command("setlang") do |ctx|
  lang = ctx.message.command_args
  ctx.session[:language] = lang if ["en", "es", "fr"].include?(lang)
  ctx.reply("Language set to #{lang}")
end

bot.command("profile") do |ctx|
  lang = ctx.session[:language] || "en"
  theme = ctx.session[:theme] || "light"
  ctx.reply("Your settings:\nLanguage: #{lang}\nTheme: #{theme}")
end
```

Broadcast to All Users

```ruby
# Store user IDs when they start the bot
bot.command("start") do |ctx|
  user_id = ctx.from.id
  # In production, save to database instead of global variable
  $users ||= []
  $users << user_id unless $users.include?(user_id)
  ctx.reply("Welcome!")
end

# Admin command to broadcast
bot.command("broadcast") do |ctx|
  if ADMIN_IDS.include?(ctx.from.id)
    message = ctx.message.command_args
    $users.each do |user_id|
      begin
        ctx.api.call("sendMessage", chat_id: user_id, text: message)
        sleep 0.1 # Be nice to Telegram's rate limits
      rescue => e
        puts "Failed to send to #{user_id}: #{e.message}"
      end
    end
    ctx.reply("Broadcast sent to #{$users.size} users")
  end
end
```

Command Aliases

```ruby
# Multiple commands for same action
["start", "hello", "hi"].each do |cmd|
  bot.command(cmd) do |ctx|
    ctx.reply("Welcome to the bot! Use /help for commands.")
  end
end
```

---

🚨 Error Handling

Global Error Handler

```ruby
bot.error do |error, ctx|
  ctx&.reply("❌ Something went wrong! Our developers have been notified.")
  puts "ERROR: #{error.class}: #{error.message}"
  puts error.backtrace if error.backtrace
  # Send to error tracking service (e.g., Sentry)
end
```

Safe File Operations

```ruby
bot.command("getfile") do |ctx|
  begin
    if File.exist?("data.txt")
      ctx.document(File.open("data.txt"))
    else
      ctx.reply("File not found")
    end
  rescue => e
    ctx.reply("Error reading file: #{e.message}")
  end
end
```

API Error Handling

```ruby
bot.on(:message) do |ctx|
  begin
    response = ctx.reply("Processing...")
    # response is an HTTPX request object
    response.wait
    if response.error
      ctx.reply("Telegram API error: #{response.error.message}")
    end
  rescue Telegem::API::NetworkError => e
    ctx.reply("Network issue: #{e.message}")
  rescue => e
    ctx.reply("Unexpected error")
  end
end
```

---

☁️ Deployment

Render.com Deployment Files

bot.rb

```ruby
require 'telegem'

bot = Telegem.new(ENV['TELEGRAM_BOT_TOKEN'])

# Your bot logic here
bot.command("start") { |ctx| ctx.reply("Bot is live on Render! ☁️") }
bot.on(:message) { |ctx| ctx.reply("Echo: #{ctx.message.text}") }

# Auto-start webhook in production
if ENV['RACK_ENV'] == 'production'
  Telegem.webhook(bot)
else
  bot.start_polling # For local development
end
```

Gemfile

```ruby
source 'https://rubygems.org'
gem 'telegem'
```

config.ru (Required for Render)

```ruby
require './bot'
run ->(env) { [200, {}, ['Telegem Bot Server']] }
```

Environment Variables Template (.env.local)

```bash
TELEGRAM_BOT_TOKEN=123456:ABCdefGHIjklMNOpqrsTUVwxyz
TELEGRAM_SECRET_TOKEN= # Auto-generated if not set
PORT=3000
RACK_ENV=production
```

Health Check Endpoint (For Cloud Platforms)

```ruby
# Add to your bot.rb for platforms that require /health
require 'rack'
app = Rack::Builder.new do
  map "/health" do
    run ->(env) { [200, {}, [{ status: "ok", bot: "running" }.to_json]] }
  end
  # ... rest of your app
end
```

---

🎯 Pro Tips

1. Use .env files for local development with the dotenv gem
2. Store user data in a database (SQLite, PostgreSQL) instead of memory for persistence
3. Respect rate limits: Add small delays (sleep 0.1) when sending many messages
4. Use ctx.with_typing for operations longer than 1-2 seconds
5. Test with multiple users using Telegram's @BotFather test feature

---

Need more recipes? Join our community and ask! https://img.shields.io/badge/🍳-t.me/telegem__me2-blue?style=flat&logo=telegram

Copy. Paste. Ship. 🚀

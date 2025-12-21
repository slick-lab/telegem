Make it cookbook.md in the main directory. Here's why:

Naming Convention:

```
docs/          # ❌ Too formal
COOKBOOK       # ❌ All caps is aggressive
recipes.md     # ❌ Cute but unclear
cookbook.md    # ✅ Perfect - clear, friendly, standard
```

Standard Open-Source Patterns:

GitHub Style:

```
README.md       # First thing people see
CONTRIBUTING.md # How to help
COOKBOOK.md     # Recipes/examples (growing trend)
```

Your Structure:

# 🍳 Telegem Cookbook

Quick copy-paste recipes for common bot tasks. 
Each recipe is standalone and ready to use!

## 📋 Table of Contents
- [Sending Media](#-sending-media)
- [Handling Files](#-handling-files)  
- [Building Forms](#-building-forms)
- [Admin Commands](#-admin-commands)
- [Database Patterns](#-database-patterns)
- [Utility Helpers](#-utility-helpers)

---

## 📸 Sending Media

### Send Photo from URL
```ruby
bot.command('cat') do |ctx|
  ctx.reply "Here's a random cat! 🐱"
  ctx.photo("https://cataas.com/cat")
end
```

Send Photo from File

```ruby
bot.command('logo') do |ctx|
  File.open("logo.png", "rb") do |file|
    ctx.photo(file, caption: "Our logo!")
  end
end
```

Send Multiple Photos (Album)

```ruby
bot.command('album') do |ctx|
  photos = [
    "https://example.com/photo1.jpg",
    "https://example.com/photo2.jpg",
    InputFile.new(File.open("local.jpg"))
  ]
  
  # Send as media group
  ctx.api.call('sendMediaGroup', {
    chat_id: ctx.chat.id,
    media: photos.map { |p| { type: 'photo', media: p } }
  })
end
```

---

📁 Handling Files

Receive and Save Document

```ruby
bot.on(:message) do |ctx|
  if ctx.message.document
    file_id = ctx.message.document.file_id
    
    # Get file info
    file = ctx.api.call('getFile', file_id: file_id)
    
    # Download file
    file_url = "https://api.telegram.org/file/bot#{ctx.bot.token}/#{file['file_path']}"
    download_and_save(file_url, "uploads/#{file_id}")
    
    ctx.reply "✅ File saved!"
  end
end
```

File Size Check

```ruby
MAX_SIZE = 20 * 1024 * 1024  # 20MB

bot.on(:message) do |ctx|
  if ctx.message.document&.file_size.to_i > MAX_SIZE
    ctx.reply "⚠️ File too large (max 20MB)"
    return
  end
end
```

---

📝 Building Forms

Simple Contact Form

```ruby
bot.scene :contact_form do
  step :ask_name do |ctx|
    ctx.reply "What's your name?"
  end
  
  step :ask_email do |ctx|
    ctx.session[:name] = ctx.message.text
    ctx.reply "What's your email?"
  end
  
  step :ask_message do |ctx|
    ctx.session[:email] = ctx.message.text
    ctx.reply "What's your message?"
  end
  
  step :submit do |ctx|
    ctx.session[:message] = ctx.message.text
    
    # Send to admin
    admin_message = <<~MSG
      📨 New Contact Form:
      
      Name: #{ctx.session[:name]}
      Email: #{ctx.session[:email]}
      Message: #{ctx.session[:message]}
    MSG
    
    ctx.api.call('sendMessage', {
      chat_id: ADMIN_ID,
      text: admin_message
    })
    
    ctx.reply "✅ Message sent! We'll reply soon."
    ctx.leave_scene
  end
end
```

---

👑 Admin Commands

Admin Middleware

```ruby
ADMIN_IDS = [123456, 789012].freeze

class AdminOnly
  def call(ctx, next_middleware)
    if ADMIN_IDS.include?(ctx.from.id)
      next_middleware.call(ctx)
    else
      ctx.reply "⛔ Admin only"
    end
  end
end

bot.use AdminOnly.new
```

Broadcast to All Users

```ruby
bot.command('broadcast') do |ctx|
  # Get all user IDs from database
  user_ids = User.pluck(:telegram_id)
  
  ctx.reply "Broadcasting to #{user_ids.size} users..."
  
  Async do
    user_ids.each do |user_id|
      begin
        ctx.api.call('sendMessage', {
          chat_id: user_id,
          text: "📢 Announcement: #{ctx.message.text.sub('/broadcast ', '')}"
        })
        sleep(0.1)  # Rate limiting
      rescue => e
        logger.error("Failed to send to #{user_id}: #{e.message}")
      end
    end
  end
  
  ctx.reply "✅ Broadcast sent!"
end
```

---

🗄️ Database Patterns

ActiveRecord Integration

```ruby
class User < ActiveRecord::Base
  def self.from_telegram(ctx)
    find_or_create_by(telegram_id: ctx.from.id) do |user|
      user.username = ctx.from.username
      user.first_name = ctx.from.first_name
      user.last_name = ctx.from.last_name
    end
  end
end

bot.command('profile') do |ctx|
  user = User.from_telegram(ctx)
  
  profile = <<~PROFILE
    👤 Your Profile:
    
    ID: #{user.telegram_id}
    Name: #{user.first_name} #{user.last_name}
    Joined: #{user.created_at.strftime('%Y-%m-%d')}
    Messages: #{user.messages_count}
  PROFILE
  
  ctx.reply profile
end
```

Redis Session Store

```ruby
require 'redis'
require 'json'

class RedisSessionStore
  def initialize(redis = Redis.new)
    @redis = redis
    @prefix = "telegem:session"
  end
  
  def get(user_id)
    data = @redis.get("#{@prefix}:#{user_id}")
    data ? JSON.parse(data, symbolize_names: true) : {}
  end
  
  def set(user_id, data)
    @redis.setex("#{@prefix}:#{user_id}", 3600, data.to_json)
  end
end

# Use it
bot = Telegem.new(token, session_store: RedisSessionStore.new)
```

---

🛠️ Utility Helpers

Formatting Helper

```ruby
module Formatters
  def self.markdown(text)
    # Escape MarkdownV2 special characters
    text.gsub(/[_*[\]()~`>#+\-=|{}.!]/, '\\\\\0')
  end
  
  def self.html(text)
    # Simple HTML escaping
    text.gsub('&', '&amp;')
        .gsub('<', '&lt;')
        .gsub('>', '&gt;')
  end
end

bot.command('bold') do |ctx|
  text = ctx.message.text.sub('/bold ', '')
  ctx.reply "*#{Formatters.markdown(text)}*", parse_mode: 'MarkdownV2'
end
```

Pagination Helper

```ruby
class Paginator
  def initialize(items, per_page: 5)
    @items = items
    @per_page = per_page
  end
  
  def page(number)
    start = (number - 1) * @per_page
    @items.slice(start, @per_page)
  end
  
  def total_pages
    (@items.size.to_f / @per_page).ceil
  end
end

bot.command('list') do |ctx|
  items = (1..50).to_a  # Your data
  paginator = Paginator.new(items)
  page_num = ctx.session[:page] || 1
  
  # Show page
  page_items = paginator.page(page_num)
  ctx.reply "Page #{page_num}/#{paginator.total_pages}\n#{page_items.join(', ')}"
  
  # Add navigation buttons
  keyboard = Telegem::Markup.inline do
    row callback("⬅️ Prev", "page_#{page_num-1}") if page_num > 1
    row callback("Next ➡️", "page_#{page_num+1}") if page_num < paginator.total_pages
  end
  
  ctx.reply "Navigate:", reply_markup: keyboard
end
```

---

🚀 Deployment Recipes

Dockerfile

```dockerfile
FROM ruby:3.2-alpine

WORKDIR /app

# Install dependencies
RUN apk add --no-cache build-base git

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs=4 --retry=3

# Copy app
COPY . .

# Run bot
CMD ["ruby", "bot.rb"]
```

Docker Compose

```yaml
version: '3.8'
services:
  bot:
    build: .
    environment:
      - TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
      - REDIS_URL=redis://redis:6379
      - DATABASE_URL=postgres://postgres:password@db:5432/bot
    depends_on:
      - redis
      - db
  
  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
  
  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=bot
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

---

🆘 Troubleshooting

"Token Invalid" Error

```ruby
# Check your token format
token = ENV['TELEGRAM_BOT_TOKEN']

# Should be: 1234567890:ABCdefGHIjklMNOpqrSTUvwxYZ
# Has two parts separated by colon
if token.nil? || token.split(':').size != 2
  puts "❌ Invalid token format!"
  exit 1
end
```

"Bot Not Responding"

```ruby
# Add logging middleware
bot.use do |ctx, next_middleware|
  puts "📨 Received: #{ctx.message&.text}"
  next_middleware.call(ctx)
  puts "✅ Handled"
end
```

---

🎯 Quick Search

Looking for something specific?

• Photos → Send Photo from URL
• Files → Receive and Save Document
• Database → ActiveRecord Integration
• Admin → Admin Middleware
• Deploy → Dockerfile

---

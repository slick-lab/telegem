
# Getting Started with Telegem 🚀

Build your first Telegram bot in 5 minutes with Ruby!

## 📋 Prerequisites

### 1. Install Ruby
```bash
# Check your Ruby version
ruby --version
# Should be 2.7 or higher (Ruby 3.0+ recommended)
```

2. Install Bundler (Optional but recommended)

```bash
gem install bundler
```

🎯 Quick Start - Your First Bot in 5 Minutes

Step 1: Get Your Bot Token

1. Open Telegram, search for @BotFather
2. Send /newbot and follow the prompts
3. Copy your token (looks like: 1234567890:ABCdefGHIjklMNOpqrsTUVwxyz)

https://via.placeholder.com/800x400.png?text=Screenshot+of+BotFather+conversation

Step 2: Create Your Bot

Option A: Using Bundler (Recommended)

```bash
# Create a new directory
mkdir my-telegram-bot
cd my-telegram-bot

# Create Gemfile
echo "source 'https://rubygems.org'
gem 'telegem'" > Gemfile

# Install gem
bundle install
```

Option B: Direct Install

```bash
gem install telegem
```

Step 3: Write Your Bot Code

Create bot.rb:

```ruby
require 'telegem'

# Initialize with your token
bot = Telegem.new(ENV['BOT_TOKEN'])

# Handle /start command
bot.command('start') do |ctx|
  ctx.reply("Hello #{ctx.from.first_name}! 👋")
  ctx.reply("I'm your first Telegem bot!")
end

# Echo messages
bot.on(:message) do |ctx|
  ctx.reply("You said: #{ctx.message.text}")
end

# Start the bot (polling mode for development)
bot.start_polling
```

Step 4: Run Your Bot

```bash
# Set your token (on Linux/Mac)
export BOT_TOKEN="your_token_here"

# On Windows:
# set BOT_TOKEN=your_token_here

# Run the bot
ruby bot.rb
```

Expected Output:

```
🤖 Starting Telegem bot (polling mode)...
✅ Bot is running!
```

Step 5: Test Your Bot

1. Open Telegram, search for your bot (the username you gave @BotFather)
2. Send /start
3. You should see: "Hello [Your Name]! 👋"

🎉 Congratulations! Your bot is alive!

🚀 Next Steps

Choose Your Development Mode

Polling Mode (Development/Local)

```ruby
# Good for testing
bot.start_polling(
  timeout: 30,
  limit: 100
)
```

Webhook Mode (Production)

```ruby
# One line - auto-detects cloud platform
bot.webhook.run
# Works with: Render, Railway, Heroku, Fly.io
```

Add More Features

Keyboard Example:

```ruby
bot.command('menu') do |ctx|
  keyboard = Telegem.keyboard do
    row "Option 1", "Option 2"
    row "Cancel"
  end
  
  ctx.reply("Choose an option:", reply_markup: keyboard)
end
```

Inline Keyboard Example:

```ruby
bot.command('vote') do |ctx|
  inline = Telegem.inline do
    row button "👍 Like", callback_data: "like"
    row button "👎 Dislike", callback_data: "dislike"
  end
  
  ctx.reply("Rate this:", reply_markup: inline)
end

# Handle button clicks
bot.on(:callback_query) do |ctx|
  ctx.answer_callback_query(text: "Thanks for voting!")
end
```

📁 Project Structure

For larger projects, organize your code:

```
my-bot/
├── bot.rb              # Main entry point
├── Gemfile
├── Gemfile.lock
├── config/
│   └── environment.rb  # Load environment
├── handlers/
│   ├── commands.rb     # Command handlers
│   ├── messages.rb     # Message handlers
│   └── callbacks.rb    # Callback handlers
└── .env               # Environment variables
```

Example modular structure: See examples/modular-bot

🔧 Configuration

Environment Variables

Create .env file:

```bash
BOT_TOKEN=your_token_here
RACK_ENV=development
PORT=3000
```

Load with dotenv gem:

```ruby
# Gemfile
gem 'dotenv', groups: [:development, :test]

# In your bot.rb
require 'dotenv'
Dotenv.load
```

Bot Options

```ruby
bot = Telegem.new(ENV['BOT_TOKEN'],
  logger: Logger.new('bot.log'),      # Custom logger
  timeout: 60,                        # API timeout
  max_threads: 20,                    # Worker threads
  session_store: custom_store         # Custom session storage
)
```

🐛 Troubleshooting

Common Issues

1. Bot not responding?

```bash
# Check if bot is running
ps aux | grep ruby

# Check logs
tail -f bot.log
```

2. Token invalid?

· Verify with @BotFather using /token
· Make sure token starts with numbers and has a colon

3. Webhook failing on cloud platforms?

· Set PORT environment variable
· Enable "Always On" on Render ($7/month)
· Check platform logs

4. Getting rate limited?

```ruby
bot.start_polling(
  timeout: 30,      # Increase timeout
  limit: 10         # Reduce updates per request
)
```

🎮 Example Bots

See real working bots built with Telegem:

Beginner Examples

· Echo Bot - Simple message repeater
· Pizza Order Bot - Food ordering with scenes
· Survey Bot - Multi-question surveys

Intermediate Examples

· Crypto Price Bot - Real-time price updates
· File Converter Bot - Convert images/PDFs
· GitHub Notifier - GitHub webhook receiver

Advanced Examples

· E-commerce Store - Full shopping experience
· Multi-language Support Bot - Supports 5 languages
· AI Chat Bot - OpenAI integration

(Links will be added as community builds bots! Submit yours via PR!)

📚 Learning Path

1. Week 1: Build echo bot, menu bot
2. Week 2: Add database, user sessions
3. Week 3: Deploy to Render/Railway
4. Week 4: Integrate external APIs (weather, news, etc.)

🆘 Need Help?

Quick Questions

1. Check the API Reference
2. Look at examples/
3. Search GitHub Issues

Community Support

· GitHub Discussions: Ask questions
· Stack Overflow: Use tag [telegem]
· Telegram Group: @telegem_ruby

🚀 Ready for Production?

Deployment Checklist

· Use webhook mode (bot.webhook.run)
· Set up environment variables
· Add error monitoring (Sentry, etc.)
· Configure logging
· Set up backup for session data

One-Click Deploy

https://render.com/images/deploy-to-render-button.svg
https://railway.app/button.svg

📝 What's Next?

1. Master Scenes for multi-step conversations
2. Add Database for persistent storage
3. Integrate Payments for monetization
4. Build Admin Panel for bot management

---

Built something cool? Submit your bot to examples/ via Pull Request!

Need a feature? Open a GitHub Issue

Found a bug? Report it with reproduction steps

---

Happy building! 🎉 Your Telegram bot journey starts here!

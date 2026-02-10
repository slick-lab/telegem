![Telegem Logo](https://gitlab.com/ruby-telegem/telegem/-/raw/main/assets/logo.png)

Modern, blazing-fast async Telegram Bot API for Ruby - Inspired by Telegraf, built for performance.

![Gem Version](https://badge.fury.io/rb/telegem.svg) ![GitLab](https://img.shields.io/badge/gitlab-telegem-orange) ![Ruby Version](https://img.shields.io/badge/Ruby-3.0+-red.svg) ![License](https://img.shields.io/badge/License-MIT-blue.svg) ![Async I/O](https://img.shields.io/badge/Async-I/O-green.svg) 

![GitLab stars](https://img.shields.io/gitlab/stars/ruby-telegem/telegem?style=for-the-badge&logo=gitlab&color=orange)
![GitLab contributors](https://img.shields.io/gitlab/contributors/ruby-telegem/telegem?style=for-the-badge&logo=gitlab)
![GitLab last commit](https://img.shields.io/gitlab/last-commit/ruby-telegem/telegem?style=for-the-badge&logo=gitlab)
![GitLab license](https://img.shields.io/gitlab/license/ruby-telegem/telegem?style=for-the-badge&logo=gitlab)



Blazing-fast, modern Telegram Bot framework for Ruby. Inspired by Telegraf.js, built for performance with true async/await patterns.

---

✨ Features

- ⚡ True Async I/O - Built on async gem, not blocking threads
- 🎯 Telegraf-style DSL - Familiar API for JavaScript developers
- 🔌 Middleware System - Compose behavior like Express.js
- 🧙 Scene System - Multi-step conversations (wizards/forms)
- 💾 Session Management - Redis, memory, or custom stores
- ⌨️ Keyboard DSL - Clean markup builders with fluent API
- 🌐 Webhook Server - Production-ready async HTTP server
- 🏗️ Type-Safe Objects - Ruby classes for all Telegram types
- 📦 Minimal Dependencies - Just async gems + mime-types

---

🚀 Quick Start

Installation

```bash
gem install telegem
```

Or add to your Gemfile:

```ruby
gem 'telegem'
```

Your First Bot (in 60 seconds)

```ruby
require 'telegem'

# 1. Get token from @BotFather on Telegram
bot = Telegem.new('YOUR_BOT_TOKEN')

# 2. Add commands
bot.command('start') do |ctx|
  ctx.reply "Hello #{ctx.from.first_name}! 👋"
end

bot.command('help') do |ctx|
  ctx.reply "I'm your friendly Telegem bot!"
end

# 3. Start listening
puts "🤖 Bot starting..."
bot.start_polling
```

Interactive Example

```ruby
# Pizza ordering bot example
bot.command('order') do |ctx|
  keyboard = Telegem.keyboard do
    row "🍕 Margherita", "🍕 Pepperoni"
    row "🥤 Drinks", "🍰 Dessert"
    row "📞 Support", "❌ Cancel"
  end.resize.one_time
  
  ctx.reply "What would you like?", reply_markup: keyboard
end
```

---


---

🎯 Why Telegem?

vs. Other Ruby Telegram Libraries

| Telegem | telegram-bot-ruby |
| ------ | ------ |
|   fast async      |  multiple thread      |
|    non blocking request     |    slow thread based     |
| clean telegraf dsl    |  no dsl |
| scene management.   | verbose |
| middleware |  raw json | 
| clean markup dsl|.      | 

Perfect For:

- High-traffic bots needing async performance
- Complex conversations with multi-step flows
- Production deployments with webhooks & scaling
- Developers familiar with Telegraf.js/Express
- Modern Ruby (3.0+) applications

---

[📚 Documentation](https://rubydoc.info/gems/telegem/3.2.2/index)



🧩 Advanced Features

Scene System (Multi-step Conversations)

```ruby
bot.scene :registration do
  step :ask_name do |ctx|
    ctx.reply "What's your name?"
  end
  
  step :save_name do |ctx|
    ctx.session[:name] = ctx.message.text
    ctx.reply "Hi #{ctx.session[:name]}! What's your email?"
  end
  
  step :complete do |ctx|
    ctx.session[:email] = ctx.message.text
    ctx.reply "Registration complete! ✅"
    ctx.leave_scene
  end
end
```

Middleware Pipeline

```ruby
# Add cross-cutting concerns
bot.use AuthenticationMiddleware.new
bot.use RateLimiter.new(limit: 10)
bot.use LoggingMiddleware.new

# Custom middleware
bot.use do |ctx, next_middleware|
  puts "Processing message from #{ctx.from.username}"
  next_middleware.call(ctx)
end
```

Multiple Session Stores

```ruby
# Memory (development)
Telegem::Session::MemoryStore.new

# Redis (production)
require 'redis'
redis = Redis.new(url: ENV['REDIS_URL'])
Telegem::Session::RedisStore.new(redis)

# Custom (database, etc.)
class DatabaseStore
  def get(user_id); end
  def set(user_id, data); end
end
```

---

🌐 Production Deployment

Webhook Mode (Recommended)

```ruby
# Production setup
server = bot.webhook_server(
  port: ENV['PORT'] || 3000,
  endpoint: Async::HTTP::Endpoint.parse("https://#{ENV['DOMAIN']}")
)

# Set webhook automatically
  bot.set_webhook(
    url: "https://#{ENV['DOMAIN']}/webhook/#{bot.token}",
    max_connections: 40
  )
  
  server.run
end
```

Docker Deployment

```dockerfile
FROM ruby:3.2-alpine
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .
CMD ["ruby", "bot.rb"]
```

---


---

📦 Project Structure

```
my_bot/
├── bot.rb                 # Main bot file
├── Gemfile
├── config/
│   ├── initializers/     # Middleware, database setup
│   └── environments/     # Development/production configs
├── lib/
│   ├── middleware/       # Custom middleware classes
│   ├── scenes/          # Scene definitions
│   └── services/        # Business logic
├── db/                  # Database migrations
└── spec/               # Tests
```

---

[🤝 contributing](https://gitlab.com/ruby-telegem/telegem/-/blob/main/Contributing.md)



Development Setup:

```bash
git clone https://gitlab.com/ruby-telegem/telegem.git
cd telegem
bundle install
rake spec  # Run tests
```

Need Help?

- Issues - Bug reports and feature requests
- Merge Requests - Code contributions
- Discussions - Questions and ideas

---

🚧 Roadmap

Coming Soon

- Plugin System - Community plugins ecosystem
- More Session Stores - PostgreSQL, MySQL, MongoDB
- Built-in Analytics - Usage tracking & insights
- Admin Dashboard - Web interface for bot management


---

📄 License

MIT License - see LICENSE.txt for details.

---

🙏 Acknowledgments

- Inspired by Telegraf.js - Amazing Node.js Telegram framework
- Built on async - Ruby's async I/O gem
- Thanks to the Telegram team for the excellent Bot API
- Community - All contributors and users

---

🌟 Star History

[history](https://api.star-history.com/svg?repos=ruby-telegem/telegem&type=Date)

---

📞 Support & Community

- GitLab Issues: Report bugs & request features
- Examples: Example bots repository
- Chat: Join our community (Telegram group)

---

🎉 Ready to Build?

```bash
# Start building your bot now!
gem install telegem
ruby -r telegem -e "puts 'Welcome to Telegem! 🚀'"
```


---

Built with ❤️ for the Ruby community. Happy bot building! 🤖✨
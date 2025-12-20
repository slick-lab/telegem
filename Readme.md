Telegem 🤖⚡

Modern, blazing-fast async Telegram Bot API for Ruby - Inspired by Telegraf, built for performance.

![Gem Version](https://badge.fury.io/rb/telegem.svg) ![GitLab](https://img.shields.io/badge/gitlab-telegem-orange) ![Ruby Version](https://img.shields.io/badge/Ruby-3.0+-red.svg) ![License](https://img.shields.io/badge/License-MIT-blue.svg) ![Async I/O](https://img.shields.io/badge/Async-I/O-green.svg)

✨ Features

- ⚡ True Async I/O - Built on async/await, not blocking threads
- 🎯 Telegraf-style DSL - Familiar API for JavaScript developers
- 🔌 Middleware System - Compose behavior like Express.js
- 💾 Session Management - Redis, memory, file stores
- 🧙 Scene System - Wizard conversations (multi-step flows)
- ⌨️ Keyboard DSL - Clean markup builders
- 🌐 Webhook Server - Production-ready async HTTP server
- 🏗️ Type-Safe Objects - Ruby classes for all Telegram types
- 📦 Zero Dependencies (except async gems)

🚀 Installation

Add to your Gemfile:

```ruby
gem 'telegem'
```

Or install directly:

```bash
gem install telegem
```

⚡ Quick Start

```ruby
require 'telegem'

bot = Telegem.new(ENV['TELEGRAM_BOT_TOKEN'])

# Basic command
bot.command('start') do |ctx|
  ctx.reply "Welcome #{ctx.from.first_name}! 👋"
end

# Keyboard example
bot.command('menu') do |ctx|
  keyboard = ctx.keyboard do
    row "🍕 Pizza", "🍔 Burger"
    row "🚗 Order Status", "📞 Contact"
    row "❌ Cancel"
  end.resize.one_time

  ctx.reply "What would you like?", reply_markup: keyboard
end

# Start the bot
bot.start_polling  # Development
# OR
bot.webhook_server.run  # Production
```

🤝 Contributing

We love contributions! Here's how:

1. Fork the repository on GitLab
2. Clone your fork:
   ```bash
   git clone https://gitlab.com/ruby-telegem/telegem.git
   cd telegem
   ```
3. Create a branch:
   ```bash
   git checkout -b feature/awesome-feature
   ```
4. Make changes and add tests
5. Run tests:
   ```bash
   rake spec
   # or
   ruby -Ilib:test test/basic_bot_test.rb
   ```
6. Commit with descriptive messages
7. Push and create a Merge Request

Development Setup

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rake spec

# Build gem locally
gem build telegem.gemspec

# Install locally for testing
gem install ./telegem-0.1.0.gem
```

📄 License

MIT License - see LICENSE.txt for details.

🙏 Acknowledgments

· Inspired by Telegraf
· Built on async gem
· Thanks to the Telegram team for the amazing Bot API

You can see a demo of Telegem in action at [Demo Link](https://example.com/demo).

## Roadmap
- [ ] Improve documentation
- [ ] Add more examples
- [ ] Implement new features based on user feedback.

## FAQ
**Q: How do I set up a webhook?**
A: Please refer to the [Webhook Deployment](#webhook-deployment) section for detailed instructions.
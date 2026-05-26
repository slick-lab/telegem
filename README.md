# Telegem Documentation

Welcome to the comprehensive documentation for Telegem, a modern Ruby framework for building Telegram bots.

[![CodeQl](https://github.com/slick-lab/telegem/actions/workflows/github-code-scanning/codeql/badge.svg)](https://github.com/slick-lab/telegem/actions/workflows/github-code-scanning/codeql)
[![Lines of Code](https://img.shields.io/badge/LOC-2907-red)](https://github.com/slick-lab/telegem)
[![Gem Version](https://badge.fury.io/rb/telegem.svg)](https://badge.fury.io/rb/telegem)
[![Join Telegram Group](https://img.shields.io/badge/Telegram-Join%20Group-2CA5E0?style=flat-square&logo=telegram&logoColor=white)](https://t.me/r_telegem)



## Table of Contents

### Getting Started
- [README](README.md) - Main project README
- [Getting Started](getting_started.md) - Installation and basic setup
- [Core Concepts](core_concepts.md) - Understanding Telegem architecture

### Core Components
- [Bot](bot.md) - Main bot class and configuration
- [Context](context.md) - Update context and response methods
- [Handlers](handlers.md) - Command, hears, and event handlers
- [Middleware](middleware.md) - Request processing pipeline
- [Scenes](scenes.md) - Multi-step conversation flows
- [Sessions](sessions.md) - Data persistence between updates

### API & Types
- [API](api.md) - Telegram API client usage
- [Types](types.md) - Type-safe API response handling
- [Keyboards](keyboards.md) - Inline and reply keyboard DSL

### Advanced Features
- [Plugins](plugins.md) - Built-in and custom plugins
- [Webhooks](webhooks.md) - Production webhook deployment
- [Error Handling](error_handling.md) - Comprehensive error management
- [Testing](testing.md) - Unit and integration testing
- [Deployment](deployment.md) - Production deployment guides

### Examples & Guides
- [Examples](examples.md) - Complete bot examples
- [Troubleshooting](troubleshooting.md) - Common issues and solutions
- [Contributing](contributing.md) - Development guidelines
- [Changelog](changelog.md) - Version history and changes

## Quick Start

1. **Install Telegem:**
```bash
gem install telegem
```

2. **Create your first bot:**
```ruby
require 'telegem'

bot = Telegem.new(token: 'YOUR_BOT_TOKEN')

bot.command('start') do |ctx|
  ctx.reply('Hello, World!')
end

bot.start_polling
```

3. **Explore features:**
   - Add [handlers](handlers.md) for different message types
   - Use [sessions](sessions.md) for data persistence
   - Implement [scenes](scenes.md) for complex conversations
   - Deploy with [webhooks](webhooks.md) for production

## Key Features

- **Async I/O**: Built on the Async gem for high performance
- **Type Safety**: Automatic type conversion for API responses
- **Session Management**: Built-in session stores (Memory, Redis)
- **Plugin System**: Extensible with custom plugins
- **Scene System**: Complex conversation flows
- **Middleware**: Request processing pipeline
- **Error Handling**: Comprehensive error recovery
- **Testing**: Full test suite with mocking support

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Telegram API  │◄──►│   API Client    │◄──►│     Handlers     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                ▲
                                │
                    ┌─────────────────┐
                    │   Middleware    │
                    └─────────────────┘
                                ▲
                                │
                    ┌─────────────────┐
                    │    Sessions     │
                    └─────────────────┘
```

## Support

- **Documentation**: You're reading it!
- **Issues**: [GitHub Issues](https://github.com/telegem/telegem/issues)
- **Discussions**: [GitHub Discussions](https://github.com/telegem/telegem/discussions)
- **Examples**: Check the `examples/` directory

## Contributing

We welcome contributions! See our [contributing guide](contributing.md) for details.

## License

Telegem is released under the MIT License. See the main README for details.

---

**Happy bot building with Telegem! 🤖**

```ruby
gem 'telegem'
```

## Basic Usage

```ruby
require 'telegem'

bot = Telegem.new('YOUR_BOT_TOKEN')

bot.command('start') do |ctx|
  ctx.reply("Hello, #{ctx.from.first_name}!")
end

bot.start_polling
```

## Requirements

- Ruby 3.0+
- Telegram Bot Token from [@BotFather](https://t.me/botfather)

## License

MIT License - see [LICENSE](../LICENSE) file for details.

## Contributing

See [Contributing Guide](contributing.md) for development setup and contribution guidelines.</content>
<parameter name="filePath">/home/slick/telegem/docs/README.md

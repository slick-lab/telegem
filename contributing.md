# Contributing

We welcome contributions to Telegem! This document provides guidelines for contributing to the project.

## Code of Conduct

This project follows a code of conduct to ensure a welcoming environment for all contributors. By participating, you agree to:

- Be respectful and inclusive
- Focus on constructive feedback
- Accept responsibility for mistakes
- Show empathy towards other contributors
- Help create a positive community

## Getting Started

### Development Setup

1. **Fork and clone the repository:**
```bash
git clone https://github.com/your-username/telegem.git
cd telegem
```

2. **Install dependencies:**
```bash
bundle install
```

3. **Set up development environment:**
```bash
# Copy environment template
cp .env.example .env

# Edit with your values
nano .env
```

4. **Run tests:**
```bash
bundle exec rspec
```

### Project Structure

```
telegem/
├── lib/                    # Core library code
│   ├── telegem.rb         # Main module
│   ├── core/              # Core functionality
│   ├── api/               # Telegram API client
│   ├── markup/            # Keyboard DSL
│   ├── session/           # Session management
│   ├── plugins/           # Built-in plugins
│   └── webhook/           # Webhook server
├── test/                  # Test files
├── docs/                  # Documentation
├── examples/              # Example bots
├── bin/                   # Executables
└── spec/                  # RSpec tests
```

## Development Workflow

### 1. Choose an Issue

- Check [GitHub Issues](https://github.com/telegem/telegem/issues) for open tasks
- Look for issues labeled `good first issue` or `help wanted`
- Comment on the issue to indicate you're working on it

### 2. Create a Branch

```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/issue-number-description
```

### 3. Make Changes

- Write clear, concise commit messages
- Follow the existing code style
- Add tests for new functionality
- Update documentation as needed

### 4. Test Your Changes

```bash
# Run full test suite
bundle exec rspec

# Run specific test
bundle exec rspec spec/path/to/test_spec.rb

# Run with coverage
COVERAGE=true bundle exec rspec
```

### 5. Submit a Pull Request

- Push your branch to GitHub
- Create a pull request with a clear description
- Reference any related issues
- Wait for review and address feedback

## Coding Standards

### Ruby Style Guide

We follow the [Ruby Style Guide](https://rubystyle.guide/) with some modifications:

- Use 2 spaces for indentation
- Use single quotes for strings unless interpolation is needed
- Use snake_case for methods and variables
- Use CamelCase for classes and modules
- Limit lines to 100 characters
- Use trailing commas in multi-line structures

### Example Code Style

```ruby
# Good
class UserHandler
  def initialize(bot, user_id)
    @bot = bot
    @user_id = user_id
  end

  def send_welcome_message
    @bot.api.call('sendMessage',
                  chat_id: @user_id,
                  text: 'Welcome!')
  end
end

# Bad
class userHandler
  def initialize bot,user_id
    @bot=bot
    @user_id=user_id
  end

  def sendWelcomeMessage()
    @bot.api.call('sendMessage',{chat_id:@user_id,text:'Welcome!'})
  end
end
```

### Naming Conventions

- **Classes/Modules:** `CamelCase`
- **Methods:** `snake_case`
- **Constants:** `SCREAMING_SNAKE_CASE`
- **Files:** `snake_case.rb`
- **Directories:** `snake_case`

### Documentation

- Use YARD format for documentation
- Document all public methods
- Include examples for complex functionality
- Keep documentation up to date

```ruby
# Good
class Bot
  # Sends a message to a chat
  #
  # @param chat_id [Integer] The chat ID to send to
  # @param text [String] The message text
  # @return [Hash] The API response
  # @example
  #   bot.send_message(123, 'Hello!')
  def send_message(chat_id, text)
    # implementation
  end
end
```

## Testing

### Test Structure

- Use RSpec for testing
- Place tests in `spec/` directory
- Mirror the `lib/` structure in `spec/`
- Name test files with `_spec.rb` suffix

### Test Best Practices

```ruby
# spec/bot_spec.rb
RSpec.describe Telegem::Bot do
  let(:bot) { Telegem::Bot.new(token: 'test_token') }

  describe '#send_message' do
    it 'sends a message successfully' do
      allow(bot.api).to receive(:call).and_return({'ok' => true})

      result = bot.send_message(123, 'test')

      expect(result['ok']).to be true
    end

    it 'handles API errors' do
      allow(bot.api).to receive(:call).and_raise(Telegem::API::APIError.new('error'))

      expect { bot.send_message(123, 'test') }.to raise_error(Telegem::API::APIError)
    end
  end
end
```

### Test Coverage

- Aim for >90% code coverage
- Test both success and failure scenarios
- Mock external dependencies
- Test edge cases and error conditions

## Plugin Development

### Plugin Guidelines

1. **Create plugin class:**
```ruby
module Telegem
  module Plugins
    class MyPlugin
      def initialize(bot, *args, **options)
        @bot = bot
        @options = options
      end

      def do_something
        # Plugin logic
      end
    end
  end
end
```

2. **Add comprehensive tests**
3. **Include documentation**
4. **Handle errors gracefully**
5. **Make configuration optional**

### Plugin Checklist

- [ ] Plugin follows naming conventions
- [ ] Comprehensive error handling
- [ ] Configuration options documented
- [ ] Tests included
- [ ] Documentation added
- [ ] Dependencies listed
- [ ] Examples provided

## Documentation

### Documentation Standards

- Use Markdown for documentation
- Place docs in `docs/` directory
- Include code examples
- Cover edge cases and error scenarios
- Keep documentation current

### Documentation Checklist

- [ ] Installation instructions
- [ ] Usage examples
- [ ] API reference
- [ ] Configuration options
- [ ] Troubleshooting guide
- [ ] Changelog updates

## Pull Request Process

### Before Submitting

1. **Update tests and documentation**
2. **Ensure all tests pass**
3. **Check code style**
4. **Update CHANGELOG.md**
5. **Squash commits if needed**

### Pull Request Template

```markdown
## Description
Brief description of the changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update
- [ ] Refactoring

## Testing
- [ ] Tests added/updated
- [ ] All tests pass
- [ ] Manual testing performed

## Checklist
- [ ] Code follows style guide
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Commit messages are clear
```

### Review Process

1. **Automated checks run**
2. **Code review by maintainers**
3. **Feedback addressed**
4. **Approval and merge**

## Issue Reporting

### Bug Reports

When reporting bugs, please include:

- **Telegem version**
- **Ruby version**
- **Operating system**
- **Steps to reproduce**
- **Expected behavior**
- **Actual behavior**
- **Error messages/logs**
- **Minimal code example**

### Feature Requests

For feature requests, include:

- **Use case description**
- **Proposed implementation**
- **Benefits**
- **Potential drawbacks**

## Community

### Communication Channels

- **GitHub Issues:** Bug reports and feature requests
- **GitHub Discussions:** General discussion and questions
- **Pull Requests:** Code contributions

### Getting Help

- Check existing documentation
- Search GitHub issues
- Ask in GitHub discussions
- Review examples in `examples/` directory

## Recognition

Contributors will be:
- Listed in CHANGELOG.md
- Added to CONTRIBUTORS file
- Recognized in release notes
- Invited to become maintainers (for significant contributions)

## License

By contributing to Telegem, you agree that your contributions will be licensed under the same license as the project (MIT License).

---

Thank you for contributing to Telegem! Your help makes the framework better for everyone.</content>
<parameter name="filePath">/home/slick/telegem/docs/contributing.md
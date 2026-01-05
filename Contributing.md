🤝 Contributing to Telegem

Welcome! We're excited you want to contribute to Telegem. This guide will help you get started, whether you're fixing a bug, adding a feature, or improving documentation.

---

🎯 First Time Contributor?

Start here! We welcome contributions of all sizes:

· 🐛 Bug fixes - Found an issue? Help us fix it!
· ✨ New features - Have an idea? Let's build it!
· 📚 Documentation - Can something be clearer? Improve it!
· 🧪 Tests - Help us make Telegem more reliable
· 🌍 Examples - Share how you're using Telegem

No contribution is too small! Even fixing a typo is appreciated.

---

📋 Table of Contents

1. Code of Conduct
2. Getting Started
3. Development Setup
4. Project Structure
5. Making Changes
6. Pull Request Process
7. Coding Standards
8. Testing
9. Documentation
10. Community

---

📜 Code of Conduct

We are committed to providing a friendly, safe, and welcoming environment for all. By participating, you agree to:

· Be respectful and inclusive
· Give and receive constructive feedback gracefully
· Focus on what's best for the community
· Show empathy towards other community members

Harassment of any kind will not be tolerated. If you experience or witness unacceptable behavior, please contact the maintainers.

---

🚀 Getting Started

Find Something to Work On

Good First Issues:
Look for issues tagged with:

· good first issue - Perfect for newcomers
· help wanted - Need community help
· documentation - Docs need improvement

Want to suggest a feature?

1. Check if it already exists in issues
2. If not, open an issue to discuss first
3. Get feedback before writing code

Communication

· Discuss first - For significant changes, open an issue to discuss
· Ask questions - Don't hesitate to ask for clarification
· Be patient - Maintainers are volunteers with limited time

---

🛠️ Development Setup

1. Fork & Clone

```bash
# Fork on GitLab
# Then clone your fork
git clone https://gitlab.com/YOUR_USERNAME/telegem.git
cd telegem
```

2. Install Dependencies

```bash
# Install Ruby (3.0+ required)
ruby --version

# Install Bundler if needed
gem install bundler

# Install gem dependencies
bundle install
```

3. Set Up Your Environment

```bash
# Create a test bot token
# Get one from @BotFather on Telegram
export TEST_BOT_TOKEN="your_test_token_here"

# Optional: Set up test Redis for session tests
export REDIS_URL="redis://localhost:6379"
```

4. Verify Setup

```bash
# Run tests to ensure everything works
bundle exec rake spec

# Build the gem locally
gem build telegem.gemspec

# Test installation
gem install ./telegem-*.gem
```

---

🏗️ Project Structure

```
telegem/
├── lib/
│   ├── telegem.rb              # Main entry point
│   ├── api/                    # Telegram API client
│   │   ├── client.rb
│   │   └── types.rb
│   ├── core/                   # Core bot framework
│   │   ├── bot.rb
│   │   ├── context.rb
│   │   ├── composer.rb
│   │   └── scene.rb
│   ├── session/                # Session management
│   │   ├── middleware.rb
│   │   └── memory_store.rb
│   └── markup/                 # Keyboard builders
│       └── keyboard.rb
├── webhook/                    # Webhook server
│   └── server.rb
├── spec/                       # Tests
│   ├── unit/
│   ├── integration/
│   └── spec_helper.rb
├── examples/                   # Example bots
│   ├── pizza_bot.rb
│   └── echo_bot.rb
├── docs/                       # Documentation
│   ├── How_to_use.md
│   ├── usage.md
│   ├── cookbook.md
│   └── API.md
├── Gemfile
├── telegem.gemspec
└── Rakefile
```

---

🔧 Making Changes

1. Create a Branch

```bash
# Always work on a branch, never on main
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
# or
git checkout -b docs/improve-readme
```

2. Make Your Changes

Follow our coding standards. Write tests for new functionality.

3. Test Your Changes

```bash
# Run all tests
bundle exec rake spec

# Run specific test file
bundle exec rspec spec/core/bot_spec.rb

# Run with coverage
bundle exec rspec --format progress --coverage
```

4. Update Documentation

· Update relevant documentation
· Add examples if adding new features
· Update API reference if changing public API

5. Commit Your Changes

```bash
# Use descriptive commit messages
git commit -m "Add feature: description of change

- Detail 1 about the change
- Detail 2 about the change
- Fixes #123 (if applicable)"
```

Commit Message Guidelines:

· First line: Summary (50 chars or less)
· Blank line
· Detailed description (wrap at 72 chars)
· Reference issues: Fixes #123, Closes #456

---

🔄 Pull Request Process

1. Push Your Branch

```bash
git push origin your-branch-name
```

2. Create a Merge Request

On GitLab:

1. Click "Merge Requests" → "New Merge Request"
2. Select your branch
3. Fill in the template
4. Request review from maintainers

3. Merge Request Template

```markdown
## Description
<!-- What does this PR do? Why is it needed? -->

## Type of Change
- [ ] Bug fix (non-breaking change)
- [ ] New feature (non-breaking change)  
- [ ] Breaking change (fix/feature causing existing functionality to break)
- [ ] Documentation update
- [ ] Example/test addition

## Testing
- [ ] Added tests for new functionality
- [ ] Updated existing tests
- [ ] All tests pass locally
- [ ] Manual testing completed

## Documentation
- [ ] Updated API documentation
- [ ] Updated usage examples
- [ ] Updated README if needed

## Checklist
- [ ] Code follows project standards
- [ ] Self-reviewed my own code
- [ ] Added comments for complex logic
- [ ] No new warnings generated
```

4. Review Process

· Maintainers will review within a few days
· Address any feedback requested
· Tests must pass
· Keep discussions constructive

5. After Approval

· Maintainer will merge your PR
· Your contribution will be in the next release!
· You'll be added to contributors list

---

📏 Coding Standards

Ruby Style

Follow Ruby Style Guide with these specifics:

```ruby
# Good
def send_message(text, parse_mode: nil)
  # ...
end

# Bad  
def sendMessage(text, parse_mode = nil)
  # ...
end
```

Naming

· Modules/Classes: CamelCase
· Methods/Variables: snake_case
· Constants: SCREAMING_SNAKE_CASE

Async Patterns

```ruby
# Use Async.do for I/O operations
def fetch_data
  Async do
    await api.call('method', params)
  end
end

# Handle errors properly
Async do
  begin
    await risky_operation
  rescue => e
    logger.error("Failed: #{e.message}")
    raise
  end
end
```

Documentation

```ruby
# Document public methods
# @param [String] text The message to send
# @option options [String] :parse_mode "HTML", "Markdown", or "MarkdownV2"
# @return [Async::Task] Async task that sends the message
def reply(text, **options)
  Async do
    # ...
  end
end
```

---

🧪 Testing

Writing Tests

```ruby
# spec/core/bot_spec.rb
RSpec.describe Telegem::Core::Bot do
  describe "#command" do
    it "registers a command handler" do
      bot = described_class.new("test_token")
      bot.command('test') { |ctx| ctx.reply("Working") }
      
      expect(bot.handlers[:message].size).to eq(1)
    end
  end
end
```

Test Structure

· Unit tests - Test individual components
· Integration tests - Test component interactions
· Async tests - Test async behavior properly

Running Tests

```bash
# All tests
bundle exec rake spec

# Specific test type
bundle exec rspec spec/unit
bundle exec rspec spec/integration

# With verbose output
bundle exec rspec --format documentation

# Watch mode (development)
bundle exec guard
```

---

📚 Documentation

Documentation Types

1. API Reference (docs/API.md) - Complete method documentation
2. Usage Guides (docs/usage.md) - Advanced patterns
3. Tutorials (docs/How_to_use.md) - Beginner guides
4. Cookbook (docs/cookbook.md) - Copy-paste recipes
5. Examples (examples/) - Working bot examples

Writing Documentation

· Use clear, simple language
· Include code examples
· Show both simple and advanced usage
· Update when changing functionality

Building Examples

```bash
# Test your examples work
cd examples
ruby pizza_bot.rb --test-mode
```

---

🌍 Community

Getting Help

· Issues - Bug reports and feature requests
· Merge Requests - Code contributions
· Discussions - Questions and ideas
· Chat - Telegram group for quick questions

Recognition

All contributors are recognized in:

· README.md contributors section
· Release notes
· Project documentation

Becoming a Maintainer

Consistent contributors may be invited to become maintainers. We look for:

· Quality contributions over time
· Helpful community participation
· Understanding of project goals
· Willingness to review others' work

---

🐛 Reporting Bugs

Before Reporting

1. Check if issue already exists
2. Update to latest version
3. Try to reproduce with minimal code

Bug Report Template

```markdown
## Description
<!-- Clear description of the bug -->

## Steps to Reproduce
1. 
2. 
3. 

## Expected Behavior
<!-- What should happen -->

## Actual Behavior  
<!-- What actually happens -->

## Environment
- Telegem version:
- Ruby version:
- OS:
- Telegram Bot API token: (use test token)

## Code Example
```ruby
# Minimal code to reproduce
```

Logs/Errors

<!-- Any error messages or logs -->```

---

## 💡 Suggesting Features

### Feature Request Template
```markdown
## Problem
<!-- What problem does this solve? -->

## Solution
<!-- Describe your proposed solution -->

## Alternatives
<!-- Any alternative solutions considered -->

## Use Cases
<!-- Who needs this and how will they use it? -->

## Implementation Ideas
<!-- Technical implementation thoughts -->
```

---

🏷️ Release Process

Versioning

We follow Semantic Versioning:

· MAJOR - Breaking changes
· MINOR - New features (backwards compatible)
· PATCH - Bug fixes (backwards compatible)

Release Checklist

· All tests pass
· Documentation updated
· Examples tested
· Changelog updated
· Version bumped in lib/telegem.rb
· Git tag created
· Gem pushed to RubyGems
· Release notes published

---

🙏 Acknowledgments

Thank you for contributing! Your work helps make Telegem better for everyone.

Quick Start Recap

1. Fork & clone
2. Create branch
3. Make changes
4. Write tests
5. Update docs
6. Submit MR

Remember: Every contribution matters. Whether you're fixing a typo or adding a major feature, you're helping build something awesome!

---

❓ Still Have Questions?

· Read the documentation
· Check existing issues
· Ask in discussions
· Join our Telegram group

Happy coding! 🎉
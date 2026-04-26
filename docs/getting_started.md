# Getting Started with Telegem

This guide will walk you through creating your first Telegram bot with Telegem.

## Prerequisites

- Ruby 3.0 or higher
- A Telegram account
- Basic knowledge of Ruby

## Step 1: Create a Telegram Bot

1. Open Telegram and search for [@BotFather](https://t.me/botfather)
2. Send `/newbot` and follow the instructions
3. Save your bot token (something like `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`)

## Step 2: Install Telegem

```bash
gem install telegem
```

Or add to your Gemfile:

```ruby
source 'https://rubygems.org'

gem 'telegem'
```

## Step 3: Create Your First Bot

Create a file called `bot.rb`:

```ruby
require 'telegem'

# Initialize bot with your token
bot = Telegem.new('YOUR_BOT_TOKEN')

# Handle /start command
bot.command('start') do |ctx|
  ctx.reply("Hello, #{ctx.from.first_name}! 👋")
end

# Handle /help command
bot.command('help') do |ctx|
  ctx.reply("I'm your friendly Telegem bot! Send /start to begin.")
end

# Handle any text message
bot.hears(/.+/) do |ctx|
  ctx.reply("You said: #{ctx.message.text}")
end

# Start the bot
puts "🤖 Bot is running..."
bot.start_polling
```

## Step 4: Run Your Bot

```bash
ruby bot.rb
```

## Step 5: Test Your Bot

1. Open Telegram
2. Find your bot by username
3. Send `/start` and see the response

## Understanding the Code

### Bot Initialization

```ruby
bot = Telegem.new('YOUR_BOT_TOKEN')
```

This creates a new bot instance with your token.

### Command Handlers

```ruby
bot.command('start') do |ctx|
  # Handle /start command
end
```

Commands are messages starting with `/`. The `ctx` object contains information about the update.

### Text Message Handlers

```ruby
bot.hears(/.+/) do |ctx|
  # Handle any text message
end
```

`hears` matches messages using regular expressions.

### Context Object

The `ctx` (context) object provides access to:

- `ctx.message` - The message object
- `ctx.from` - The user who sent the message
- `ctx.chat` - The chat where the message was sent
- `ctx.reply(text)` - Send a reply

## Next Steps

- Learn about [handlers](handlers.md) for more routing options
- Explore [middleware](middleware.md) for request processing
- Check out [scenes](scenes.md) for multi-step conversations
- See [examples](examples.md) for more complex bots

## Common Issues

### "Bot token is invalid"

- Double-check your token from @BotFather
- Make sure there are no extra spaces

### "Connection refused"

- Check your internet connection
- Verify the bot token is correct

### Bot doesn't respond

- Make sure the bot is running (`ruby bot.rb`)
- Check that you've started a conversation with the bot first
- Look at the console output for errors

## Development Tips

- Use `puts` statements for debugging
- Check the [API reference](api.md) for available methods
- Join the [Telegram Bot Community](https://t.me/botcommunity) for help

## Production Deployment

For production use, consider:

- [Webhook deployment](webhooks.md) instead of polling
- [Session storage](sessions.md) for user data
- [Error handling](error_handling.md) for reliability
- [Rate limiting](middleware.md) for performance</content>
<parameter name="filePath">/home/slick/telegem/docs/getting_started.md
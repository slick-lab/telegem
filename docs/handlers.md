# Handlers and Routing

Handlers are functions that process specific types of updates from Telegram. Telegem provides a flexible routing system to match updates to handlers.

## Handler Types

### Command Handlers

Commands are messages starting with `/`. They automatically handle bot mentions.

```ruby
bot.command('start') do |ctx|
  ctx.reply("Welcome!")
end

bot.command('help') do |ctx|
  ctx.reply("Available commands: /start, /help")
end

# Commands with arguments
bot.command('echo') do |ctx|
  args = ctx.command_args
  ctx.reply(args || "No arguments provided")
end
```

Command matching:
- `/start` matches
- `/start@mybot` matches (if bot username is @mybot)
- `start` doesn't match (no slash)

### Text Pattern Handlers

Match messages using strings or regular expressions.

```ruby
# Exact string match
bot.hears('hello') do |ctx|
  ctx.reply("Hi there!")
end

# Case-insensitive match
bot.hears(/^hello$/i) do |ctx|
  ctx.reply("Hello to you!")
end

# Any message containing word
bot.hears(/bot/i) do |ctx|
  ctx.reply("You mentioned bot!")
end

# Catch-all for text messages
bot.hears(/.+/) do |ctx|
  ctx.reply("You said: #{ctx.message.text}")
end
```

### Update Type Handlers

Handle specific update types directly.

```ruby
# Callback queries (button presses)
bot.callback_query do |ctx|
  data = ctx.data
  ctx.answer_callback_query("Button pressed: #{data}")
end

# Inline queries (inline search)
bot.inline_query do |ctx|
  query = ctx.query
  # Return search results
  results = search_results_for(query)
  ctx.answer_inline_query(results)
end

# Poll answers
bot.poll_answer do |ctx|
  answer = ctx.poll_answer
  # Process poll response
end

# Chat join requests
bot.chat_join_request do |ctx|
  # Approve or deny join request
  ctx.approve_chat_join_request()
end
```

### Media Handlers

Specialized handlers for different media types.

```ruby
# Photos
bot.photo do |ctx|
  ctx.reply("Nice photo! 📸")
end

# Documents
bot.document do |ctx|
  filename = ctx.message.document.file_name
  ctx.reply("Received document: #{filename}")
end

# Audio files
bot.audio do |ctx|
  title = ctx.message.audio.title
  ctx.reply("Playing: #{title}")
end

# Videos
bot.video do |ctx|
  ctx.reply("Video received!")
end

# Voice messages
bot.voice do |ctx|
  duration = ctx.message.voice.duration
  ctx.reply("Voice message (#{duration}s)")
end

# Stickers
bot.sticker do |ctx|
  emoji = ctx.message.sticker.emoji
  ctx.reply("Sticker: #{emoji}")
end

# Locations
bot.location do |ctx|
  lat = ctx.message.location.latitude
  lng = ctx.message.location.longitude
  ctx.reply("Location: #{lat}, #{lng}")
end

# Contacts
bot.contact do |ctx|
  contact = ctx.message.contact
  ctx.reply("Contact: #{contact.first_name}")
end
```

### Generic Handlers

Use `on()` for any update type with optional filters.

```ruby
# Handle all messages
bot.on(:message) do |ctx|
  puts "Message received"
end

# Messages in private chats only
bot.on(:message, chat_type: 'private') do |ctx|
  ctx.reply("This is private")
end

# Messages containing specific text
bot.on(:message, text: /urgent/i) do |ctx|
  ctx.reply("🚨 Urgent message!")
end

# Edited messages
bot.on(:edited_message) do |ctx|
  ctx.reply("Message edited")
end

# Channel posts
bot.on(:channel_post) do |ctx|
  # Handle channel posts
end
```

## Handler Priority and Order

Handlers are checked in registration order. More specific handlers should be registered first.

```ruby
# Bad: catch-all first
bot.hears(/.+/) do |ctx|
  ctx.reply("Catch-all")
end

bot.command('start') do |ctx|  # Never reached
  ctx.reply("Start")
end

# Good: specific first
bot.command('start') do |ctx|
  ctx.reply("Start")
end

bot.hears(/.+/) do |ctx|
  ctx.reply("Catch-all")
end
```

## Filters

Use filters to match specific conditions.

### Chat Type Filters

```ruby
bot.on(:message, chat_type: 'private') do |ctx|
  # Private messages only
end

bot.on(:message, chat_type: 'group') do |ctx|
  # Group messages only
end

bot.on(:message, chat_type: 'supergroup') do |ctx|
  # Supergroup messages only
end
```

### User Filters

```ruby
# Messages from specific user
bot.on(:message, user_id: 123456) do |ctx|
  ctx.reply("Hello admin!")
end

# Messages from bots
bot.on(:message, is_bot: true) do |ctx|
  ctx.reply("Bot detected")
end
```

### Content Filters

```ruby
# Messages with photos
bot.on(:message, has_photo: true) do |ctx|
  ctx.reply("Photo received")
end

# Messages with documents
bot.on(:message, has_document: true) do |ctx|
  ctx.reply("Document received")
end

# Forwarded messages
bot.on(:message, forwarded: true) do |ctx|
  ctx.reply("Forwarded message")
end

# Reply messages
bot.on(:message, reply: true) do |ctx|
  ctx.reply("This is a reply")
end
```

### Custom Filters

```ruby
# Custom filter function
bot.on(:message, ->(ctx) { ctx.from&.username == 'admin' }) do |ctx|
  ctx.reply("Admin command")
end

# Multiple conditions
bot.on(:message, chat_type: 'group', text: /admin/i) do |ctx|
  # Admin commands in groups
end
```

## Handler Context

### Match Data

For regex handlers, match data is available.

```ruby
bot.hears(/hello (\w+)/) do |ctx|
  name = ctx.match[1]  # Captured group
  ctx.reply("Hello #{name}!")
end

bot.hears(/^\/greet (\w+) (\w+)/) do |ctx|
  first_name = ctx.match[1]
  last_name = ctx.match[2]
  ctx.reply("Greetings #{first_name} #{last_name}!")
end
```

### State and Session

Handlers have access to state and session.

```ruby
bot.hears(/set name (.+)/) do |ctx|
  name = ctx.match[1]
  ctx.session[:name] = name
  ctx.reply("Name set to #{name}")
end

bot.hears('my name') do |ctx|
  name = ctx.session[:name] || 'unknown'
  ctx.reply("Your name is #{name}")
end
```

## Dynamic Handlers

Register handlers at runtime.

```ruby
# Add command dynamically
bot.command('dynamic') do |ctx|
  ctx.reply("Dynamic command!")
end

# Conditional handlers
if ENV['ADMIN_MODE']
  bot.command('admin') do |ctx|
    # Admin commands
  end
end

# Handler factories
def create_counter_handler(name)
  bot.command(name) do |ctx|
    ctx.session[name] ||= 0
    ctx.session[name] += 1
    ctx.reply("#{name}: #{ctx.session[name]}")
  end
end

create_counter_handler('count1')
create_counter_handler('count2')
```

## Handler Removal

Handlers cannot be removed individually. To change handlers:

1. Create a new bot instance
2. Use conditional registration
3. Use middleware to filter

```ruby
# Conditional handler
bot.use do |ctx, next_middleware|
  if should_skip_handler?(ctx)
    return  # Skip handler
  end
  next_middleware.call(ctx)
end

bot.command('conditional') do |ctx|
  # Only reached if middleware allows
end
```

## Error Handling in Handlers

```ruby
bot.command('risky') do |ctx|
  begin
    risky_operation(ctx.text)
    ctx.reply("Success!")
  rescue => e
    ctx.logger.error("Handler error: #{e.message}")
    ctx.reply("Something went wrong")
  end
end
```

## Async Handlers

For long-running operations, use async.

```ruby
bot.command('long_task') do |ctx|
  ctx.reply("Processing...")

  Async do
    result = long_running_operation()
    ctx.reply("Done: #{result}")
  end
end
```

## Handler Best Practices

### 1. Keep Handlers Small

```ruby
# Bad
bot.command('process') do |ctx|
  # 50 lines of processing code
end

# Good
bot.command('process') do |ctx|
  result = process_data(ctx.text)
  ctx.reply(result)
end
```

### 2. Use Appropriate Handler Types

```ruby
# Use command for commands
bot.command('start')

# Use hears for text patterns
bot.hears(/hello/)

# Use on() for complex conditions
bot.on(:message, chat_type: 'private', has_photo: true)
```

### 3. Validate Input

```ruby
bot.command('calculate') do |ctx|
  number = ctx.command_args&.to_i
  if number.nil? || number < 0
    ctx.reply("Please provide a positive number")
    return
  end

  result = calculate(number)
  ctx.reply("Result: #{result}")
end
```

### 4. Handle Edge Cases

```ruby
bot.photo do |ctx|
  unless ctx.message.photo&.any?
    ctx.reply("No photo found")
    return
  end

  # Process photo
end
```

### 5. Use Sessions for State

```ruby
bot.hears('start quiz') do |ctx|
  ctx.session[:quiz_active] = true
  ctx.session[:question] = 1
  ctx.reply("Quiz started! Question 1...")
end

bot.hears(/.+/) do |ctx|
  if ctx.session[:quiz_active]
    # Handle quiz answer
  end
end
```

### 6. Log Important Actions

```ruby
bot.command('delete') do |ctx|
  ctx.logger.info("User #{ctx.from.id} deleting data")
  delete_user_data(ctx.from.id)
  ctx.reply("Data deleted")
end
```

## Common Patterns

### Menu Systems

```ruby
bot.command('menu') do |ctx|
  keyboard = Telegem.keyboard do
    row "📊 Stats", "⚙️ Settings"
    row "❓ Help", "🚪 Exit"
  end

  ctx.reply("Choose option:", reply_markup: keyboard)
end

bot.hears('Stats') do |ctx|
  stats = get_user_stats(ctx.from.id)
  ctx.reply("Your stats: #{stats}")
end
```

### Admin Commands

```ruby
ADMIN_IDS = [123456, 789012]

bot.command('admin') do |ctx|
  unless ADMIN_IDS.include?(ctx.from.id)
    ctx.reply("Access denied")
    return
  end

  # Admin functionality
  ctx.reply("Admin panel")
end
```

### Rate Limiting

```ruby
bot.use do |ctx, next_middleware|
  user_id = ctx.from&.id
  if user_id
    key = "rate_limit:#{user_id}"
    count = ctx.session[key] ||= 0

    if count > 10
      ctx.reply("Too many requests")
      return
    end

    ctx.session[key] = count + 1
  end

  next_middleware.call(ctx)
end
```

### Command Aliases

```ruby
['start', 'begin', 'hello'].each do |cmd|
  bot.command(cmd) do |ctx|
    ctx.reply("Welcome!")
  end
end
```

### Fallback Handlers

```ruby
# Handle unknown commands
bot.on(:message, ->(ctx) { ctx.message&.text&.start_with?('/') }) do |ctx|
  ctx.reply("Unknown command. Try /help")
end

# Handle non-text messages
bot.on(:message) do |ctx|
  unless ctx.message&.text
    ctx.reply("I only understand text messages")
  end
end
```

## Testing Handlers

```ruby
# Test helper
def simulate_message(bot, text, from_id: 123)
  update = Telegem::Types::Update.new({
    update_id: 1,
    message: {
      message_id: 1,
      from: { id: from_id, first_name: 'Test' },
      chat: { id: from_id, type: 'private' },
      date: Time.now.to_i,
      text: text
    }
  })

  ctx = Telegem::Core::Context.new(update, bot)
  bot.process_update(update)
end

# Usage
simulate_message(bot, '/start')
simulate_message(bot, 'hello world')
```

Understanding handlers is crucial for building interactive bots. Choose the right handler type and use filters to create precise routing logic.</content>
<parameter name="filePath">/home/slick/telegem/docs/handlers.md
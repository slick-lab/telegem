🧠 What is bot?

If ctx is your hands (doing things), bot is your brain (deciding what to do).

```ruby
bot = Telegem.new("YOUR_TOKEN")  # Born!

bot.command('start') do |ctx|    # Learns to respond to /start
  ctx.reply("Hello!")           # Says hello
end

bot.start_polling                # Starts listening!
```

🎯 The 5 Ways Your Bot Listens

1. bot.command() - For Slash Commands

When users type /something:

```ruby
# Basic command
bot.command('start') do |ctx|
  ctx.reply("Welcome! 👋")
end

# With arguments
bot.command('search') do |ctx|
  query = ctx.command_args  # What comes after /search
  if query.empty?
    ctx.reply("Usage: /search <something>")
  else
    ctx.reply("Searching for '#{query}'...")
  end
end

# Multiple commands, same handler
['help', 'info', 'about'].each do |cmd|
  bot.command(cmd) do |ctx|
    ctx.reply("I'm a helpful bot! 🤖")
  end
end
```

What users see:

```
User: /start
Bot: Welcome! 👋

User: /search cats
Bot: Searching for 'cats'...

User: /search
Bot: Usage: /search <something>
```

2. bot.hears() - For Text Patterns

When users say specific words or patterns:

```ruby
# Exact match
bot.hears('hello') do |ctx|
  ctx.reply("Hello there! 😊")
end

# Case-insensitive
bot.hears(/hello|hi|hey/i) do |ctx|
  ctx.reply("Greetings! 🖐️")
end

# Regex with capture groups
bot.hears(/my name is (\w+)/i) do |ctx|
  name = ctx.match[1]  # Captured part
  ctx.reply("Nice to meet you, #{name}! 👋")
end

# Pattern with wildcard
bot.hears(/I love (\w+)/) do |ctx|
  thing = ctx.match[1]
  ctx.reply("I love #{thing} too! ❤️")
end
```

What users see:

```
User: hello
Bot: Hello there! 😊

User: My name is John
Bot: Nice to meet you, John! 👋

User: I love pizza
Bot: I love pizza too! ❤️
```

3. bot.on() - For Everything Else

The Swiss Army knife handler:

```ruby
# Handle ALL messages
bot.on(:message) do |ctx|
  ctx.reply("I got a message!")
end

# Handle only photos
bot.on(:message, photo: true) do |ctx|
  ctx.reply("Nice photo! 📸")
end

# Handle only videos
bot.on(:message, video: true) do |ctx|
  ctx.reply("Cool video! 🎥")
end

# Handle only documents
bot.on(:message, document: true) do |ctx|
  ctx.reply("Thanks for the document! 📄")
end

# Handle only locations
bot.on(:message, location: true) do |ctx|
  ctx.reply("Thanks for sharing location! 📍")
end

# Filter by chat type
bot.on(:message, chat_type: 'private') do |ctx|
  ctx.reply("Private chat message!")
end

bot.on(:message, chat_type: 'group') do |ctx|
  ctx.reply("Group chat message!")
end
```

4. bot.on(:callback_query) - For Button Clicks

When users click inline buttons:

```ruby
# Handle ALL button clicks
bot.on(:callback_query) do |ctx|
  ctx.answer_callback_query(text: "Button clicked!")
  ctx.reply("You clicked: #{ctx.data}")
end

# Filter by button data
bot.on(:callback_query, data: 'yes') do |ctx|
  ctx.answer_callback_query(text: "You said YES! ✅")
  ctx.edit_message_text("Confirmed! ✅")
end

bot.on(:callback_query, data: 'no') do |ctx|
  ctx.answer_callback_query(text: "You said NO! ❌")
  ctx.edit_message_text("Cancelled! ❌")
end

# Pattern matching button data
bot.on(:callback_query) do |ctx|
  if ctx.data.start_with?('vote_')
    option = ctx.data.split('_').last
    ctx.answer_callback_query(text: "Voted for #{option}!")
    ctx.edit_message_text("You voted: #{option} ✅")
  end
end
```

5. bot.on(:inline_query) - For @bot Searches

When users type @yourbot something:

```ruby
bot.on(:inline_query) do |ctx|
  query = ctx.query  # What they typed after @yourbot

  results = [
    {
      type: "article",
      id: "1",
      title: "Result for: #{query}",
      input_message_content: {
        message_text: "You searched: #{query}"
      }
    }
  ]

  ctx.answer_inline_query(results)
end
```

🎭 Real Bot Examples

Example 1: Echo Bot (Beginners)

```ruby
bot = Telegem.new("TOKEN")

# Respond to /start
bot.command('start') do |ctx|
  ctx.reply("I echo everything you say! 🔊")
end

# Echo all messages
bot.on(:message) do |ctx|
  if ctx.message.text
    ctx.reply("You said: #{ctx.message.text}")
  end
end

bot.start_polling
```

Example 2: Quiz Bot (Intermediate)

```ruby
bot = Telegem.new("TOKEN")

QUESTIONS = [
  { q: "2 + 2?", a: "4", options: ["3", "4", "5"] },
  { q: "Capital of France?", a: "Paris", options: ["London", "Paris", "Berlin"] }
]

bot.command('quiz') do |ctx|
  question = QUESTIONS.sample

  inline = Telegem.inline do
    question[:options].each do |option|
      row button option, callback_data: "answer_#{option}"
    end
  end

  ctx.reply(question[:q], reply_markup: inline)
  ctx.session[:correct] = question[:a]
end

bot.on(:callback_query) do |ctx|
  answer = ctx.data.split('_').last
  correct = ctx.session[:correct]

  if answer == correct
    ctx.answer_callback_query(text: "✅ Correct!")
    ctx.edit_message_text("🎉 Correct! The answer is #{correct}")
  else
    ctx.answer_callback_query(text: "❌ Wrong! It's #{correct}")
  end
end
```

Example 3: Support Bot (Advanced)

```ruby
bot = Telegem.new("TOKEN")

# Main menu
bot.command('start') do |ctx|
  keyboard = Telegem.keyboard do
    row "Report Bug", "Request Feature"
    row "Ask Question", "Contact Human"
  end

  ctx.reply("Support Menu:", reply_markup: keyboard)
end

# Handle menu choices
bot.hears("Report Bug") do |ctx|
  ctx.reply("Describe the bug:")
  ctx.state[:collecting_bug] = true
end

bot.hears("Ask Question") do |ctx|
  ctx.reply("What's your question?")
  ctx.state[:collecting_question] = true
end

# Collect user input
bot.on(:message) do |ctx|
  if ctx.state[:collecting_bug]
    bug = ctx.message.text
    # Save to database...
    ctx.reply("Bug reported! ID: ##{rand(1000)}")
    ctx.state.delete(:collecting_bug)

  elsif ctx.state[:collecting_question]
    question = ctx.message.text
    # Save to database...
    ctx.reply("Question logged! We'll reply soon.")
    ctx.state.delete(:collecting_question)
  end
end
```

⚡ Pro Tips & Patterns

Tip 1: Organize Your Handlers

```ruby
# Instead of one giant file:
# handlers/commands.rb
def setup_commands(bot)
  bot.command('start') { |ctx| ctx.reply("Start!") }
  bot.command('help')  { |ctx| ctx.reply("Help!") }
end

# handlers/messages.rb  
def setup_messages(bot)
  bot.on(:message, photo: true) { |ctx| ctx.reply("Photo!") }
  bot.on(:message, video: true) { |ctx| ctx.reply("Video!") }
end

# main.rb
bot = Telegem.new("TOKEN")
setup_commands(bot)
setup_messages(bot)
```

Tip 2: Use Middleware for Common Tasks

```ruby
# Log all messages
class LoggerMiddleware
  def call(ctx, next_middleware)
    puts "[#{Time.now}] #{ctx.from.id}: #{ctx.message.text}"
    next_middleware.call(ctx)
  end
end

bot.use(LoggerMiddleware.new)
```

Tip 3: Rate Limiting

```ruby
bot.command('spam') do |ctx|
  user_id = ctx.from.id

  # Allow only 5 uses per minute
  ctx.session[:spam_count] ||= 0
  ctx.session[:spam_count] += 1

  if ctx.session[:spam_count] > 5
    ctx.reply("🚫 Too many requests! Wait a minute.")
  else
    ctx.reply("Spam count: #{ctx.session[:spam_count]}")
  end
end
```

🚀 Bot Lifecycle Management

Starting Your Bot

```ruby
# Development (polling)
bot.start_polling(
  timeout: 30,   # Wait 30 seconds for updates
  limit: 100     # Get up to 100 updates at once
)

# Production (webhook)
server = bot.webhook(port: 3000)
server.run
server.set_webhook
```

Stopping Gracefully

```ruby
# In your main file
Signal.trap("INT") do
  puts "\nShutting down..."
  bot.shutdown
  exit
end

# Or handle in code
begin
  bot.start_polling
rescue Interrupt
  bot.shutdown
end
```

🎮 Interactive Challenge

Build a Fortune Cookie Bot in 15 minutes:

1. /fortune - Gives random fortune
2. Hears "tell me a joke" - Tells joke
3. Hears "I'm feeling lucky" - Random emoji response
4. Button "Get Another" - New fortune

```ruby
# Starter code
fortunes = [
  "You will find happiness with a new friend.",
  "A dream you have will come true.",
  "Now is the time to try something new.",
  "Your hard work will pay off soon."
]

bot.command('fortune') do |ctx|
  fortune = fortunes.sample
  ctx.reply("🔮 #{fortune}")

  # Your turn: Add inline button "Get Another"
end

bot.hears(/tell me a joke/i) do |ctx|
  # Your turn: Add a joke
end

# Your turn: Add button click handler
```

📋 Cheat Sheet

When user... Use... Example
- Types /command bot.command() bot.command('start')
- Says exact word bot.hears('word') bot.hears('hello')
- Says pattern bot.hears(/pattern/) bot.hears(/I love \w+/)
- Sends any message bot.on(:message) bot.on(:message)
- Sends photo bot.on(:message, photo: true) Handles only photos
- Clicks button bot.on(:callback_query) Handles inline buttons
- Searches @bot bot.on(:inline_query) Inline mode results

🔧 Debugging Common Issues

Handler Not Firing?

```ruby
# Add logging
bot.on(:message) do |ctx|
  puts "DEBUG: Got message: #{ctx.message.text}"
  # Your handler...
end
```

Buttons Not Working?

```ruby
bot.on(:callback_query) do |ctx|
  puts "DEBUG: Button data: #{ctx.data}"
  ctx.answer_callback_query  # ← DON'T FORGET THIS!
  # Your handler...
end
```

Multiple Handlers Conflict?

Handlers run in order. First matching handler wins!

```ruby
bot.command('test') { |ctx| ctx.reply("First!") }
bot.command('test') { |ctx| ctx.reply("Second!") }  # Never runs!
```

---

Your bot is now ready to listen! Start with one handler, test it, add another. Like teaching a child new words, one at a time. 🧒→🤖

Remember: Every great bot started with just /start. Build that, then add one more feature. Then another. Consistency beats complexity!
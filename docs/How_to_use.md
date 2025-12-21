🎓 How to Use Telegem: Your Friendly Guide

Welcome! This guide will walk you through everything Telegem can do, step by step. No prior bot experience needed!

📚 How This Guide Works

We'll learn by doing! Each section has:

· 🧪 Try This - Hands-on examples in IRB (Ruby's interactive console)
· 💡 What's Happening - Plain English explanations
· 🔧 Real Example - Practical bot code you can use
· 📝 Key Points - Important things to remember

Ready? Let's begin our bot-building journey! 🚀

---

🏁 Part 1: Your First Bot (5 Minutes)

🧪 Try This First:

Open your terminal and type:

```bash
irb
```

Then type (or copy-paste):

```ruby
require 'telegem'
puts "✅ Telegem loaded! Version: #{Telegem::VERSION}"
```

You should see: ✅ Telegem loaded! Version: 0.1.2

💡 What's Happening:

You just loaded the Telegem library! This is like opening a toolbox before building something. The library is now ready to use in your Ruby session.

🔧 Real Example:

Let's create the simplest possible bot:

```ruby
# simplest_bot.rb
require 'telegem'

# Create your bot (replace with real token)
bot = Telegem.new('YOUR_TOKEN_HERE')

# Add a command
bot.command('start') do |ctx|
  ctx.reply "Hello! I'm alive! 🎉"
end

# Start listening for messages
bot.start_polling
```

📝 Key Points:

1. Every bot needs a token (from @BotFather on Telegram)
2. Commands start with / like /start, /help
3. ctx means "context" - it's your control panel for that chat
4. ctx.reply sends a message back

---

🧩 Part 2: Understanding the "Context" (ctx)

Think of ctx as your bot's hands and eyes in a conversation. It can:

· See the message
· Know who sent it
· Send replies
· Remember things

🧪 Try This in IRB:

```ruby
# Let's explore what ctx can do
class MockContext
  def from
    OpenStruct.new(first_name: "Alex", id: 12345)
  end
  
  def chat
    OpenStruct.new(id: 999, type: "private")
  end
  
  def message
    OpenStruct.new(text: "/start", command?: true)
  end
end

ctx = MockContext.new
puts "User: #{ctx.from.first_name}"
puts "Chat ID: #{ctx.chat.id}"
puts "Is command? #{ctx.message.command?}"
```

💡 What ctx Contains:

· ctx.from - Who sent the message (name, ID, username)
· ctx.chat - Where it was sent (private chat, group, channel)
· ctx.message - The actual message text
· ctx.reply - Method to send messages back
· ctx.session - Memory for this user (more on this later!)

🔧 Real Example - Personal Greeting:

```ruby
bot.command('hello') do |ctx|
  # Use ctx.from to personalize
  name = ctx.from.first_name
  ctx.reply "Hi #{name}! 👋 Nice to meet you!"
  
  # Use ctx.chat to know where we are
  if ctx.chat.type == "group"
    ctx.reply "Thanks for adding me to this group!"
  end
end
```

---

🗣️ Part 3: Handling Different Message Types

Bots can handle more than just commands! Here's what you can listen for:

1. Commands (Start with /)

```ruby
bot.command('help') do |ctx|
  ctx.reply "I'm here to help!"
end
```

2. Text Messages (Any text)

```ruby
bot.on(:message) do |ctx|
  # Skip commands (they're handled above)
  next if ctx.message.command?
  
  user_text = ctx.message.text
  ctx.reply "You said: #{user_text}"
end
```

3. Button Clicks (Inline keyboard buttons)

```ruby
bot.on(:callback_query) do |ctx|
  # ctx.data contains what button was clicked
  button_data = ctx.data
  ctx.reply "You clicked: #{button_data}"
end
```

🧪 Try This Pattern:

```ruby
bot.on(:message) do |ctx|
  if ctx.message.command?
    puts "It's a command!"
  elsif ctx.message.text.include?("?")
    puts "It's a question!"
  else
    puts "Regular message"
  end
end
```

---

🎨 Part 4: Making Interactive Bots (Keyboards!)

Why Keyboards?

Instead of typing commands, users can click buttons! Two types:

1. Reply Keyboard (Appears at bottom)

```ruby
keyboard = Telegem::Markup.keyboard do
  row "Yes", "No", "Maybe"
  row "Cancel"
end

ctx.reply "Do you agree?", reply_markup: keyboard
```

2. Inline Keyboard (Appears in message)

```ruby
inline = Telegem::Markup.inline do
  row callback("👍 Like", "like_123"),
      callback("👎 Dislike", "dislike_123")
  row url("🌐 Website", "https://example.com")
end

ctx.reply "Rate this:", reply_markup: inline
```

🧪 Try Building a Menu:

```ruby
# In IRB, try building this menu
require 'telegem'

menu = Telegem::Markup.keyboard do
  row "🍕 Pizza", "🍔 Burger", "🌮 Taco"
  row "🥤 Drinks", "🍰 Dessert"
  row "📞 Call Staff", "❌ Cancel"
end

puts "Your menu looks like:"
puts menu.to_h
```

---

💾 Part 5: Remembering Things (Sessions)

Bots have short-term memory! This is called "session."

The Magic of ctx.session:

```ruby
bot.command('counter') do |ctx|
  # Initialize if first time
  ctx.session[:count] ||= 0
  
  # Increase counter
  ctx.session[:count] += 1
  
  ctx.reply "You've used this command #{ctx.session[:count]} times!"
end
```

What Can You Store?

· Preferences (language, theme)
· Shopping carts (items being purchased)
· Game scores (points, levels)
· Form data (half-filled applications)

🧪 Try Session in IRB:

```ruby
# Simulate how session works
session = {}

# First visit
session[:visits] ||= 0
session[:visits] += 1
puts "Visit #{session[:visits]}"

# Second "visit"
session[:visits] += 1
puts "Visit #{session[:visits]}"

# It remembers!
```

---

🧙 Part 6: Multi-Step Conversations (Scenes)

Sometimes you need back-and-forth conversations. That's where Scenes shine!

Real World Example - Pizza Order:

1. Bot: "What pizza do you want?"
2. User: "Pepperoni"
3. Bot: "What size?"
4. User: "Large"
5. Bot: "Confirm order?"

Each step is a Scene Step!

🔧 Scene Example:

```ruby
bot.scene :order_pizza do
  step :ask_type do |ctx|
    ctx.reply "What pizza do you want? (Margherita/Pepperoni/Veggie)"
  end
  
  step :save_type do |ctx|
    # Save their choice
    ctx.session[:pizza_type] = ctx.message.text
    ctx.reply "Great! Now what size? (Small/Medium/Large)"
  end
  
  step :save_size do |ctx|
    ctx.session[:size] = ctx.message.text
    ctx.reply "Order confirmed: #{ctx.session[:size]} #{ctx.session[:pizza_type]}!"
    ctx.leave_scene  # Conversation done!
  end
end

# Start the scene
bot.command('order') do |ctx|
  ctx.enter_scene(:order_pizza)
end
```

💡 Scene Thinking:

Scenes are like mini-programs inside your bot. Each has:

1. Steps - Questions to ask
2. Memory - Remembers answers
3. Flow - Goes from step to step automatically

---

🔌 Part 7: Adding Superpowers (Middleware)

Middleware are plugins that run on every message. Think of them as filters or enhancers.

Simple Logger Middleware:

```ruby
bot.use do |ctx, next_middleware|
  # Runs BEFORE handling the message
  puts "#{Time.now} - #{ctx.from.first_name}: #{ctx.message&.text}"
  
  # Pass to next middleware (or the command handler)
  next_middleware.call(ctx)
  
  # Runs AFTER handling
  puts "Message handled!"
end
```

Built-in Middleware You Get:

1. Session Middleware - Automatic ctx.session
2. Error Handler - Catch and report errors
3. Rate Limiter (coming soon!) - Prevent spam

---

🌐 Part 8: Going Live (Webhooks vs Polling)

Two Ways to Run Your Bot:

1. Polling (Easy - for development)

```ruby
bot.start_polling  # Checks for messages every second
```

Like checking your mailbox every minute

2. Webhooks (Better - for production)

```ruby
server = bot.webhook_server(port: 3000)
server.run  # Telegram sends messages to you
```

Like having a mail slot - messages arrive immediately

🧪 Understanding the Difference:

```ruby
# Polling (YOU ask Telegram)
# Bot: "Any new messages?"
# Telegram: "No"
# Bot: "How about now?"
# Telegram: "Still no"
# ... (every second)

# Webhook (Telegram tells YOU)
# *Message arrives*
# Telegram: "Hey bot, here's a message!"
# Bot: "Thanks, I'll handle it!"
```

---

🚨 Part 9: Handling Problems (Error Handling)

When Things Go Wrong:

```ruby
bot.error do |error, ctx|
  # Log the error
  puts "ERROR: #{error.class}: #{error.message}"
  
  # Tell user (politely!)
  ctx.reply "Oops! Something went wrong. Try again? 🤔"
  
  # Or notify admin
  ctx.api.call('sendMessage', 
    chat_id: ADMIN_ID,
    text: "Bot error: #{error.message}"
  )
end
```

Common Errors & Fixes:

1. Invalid Token - Check @BotFather for correct token
2. Network Issues - Bot can't reach Telegram servers
3. Rate Limits - Too many messages too fast
4. Bad Parameters - Sending wrong data to API

---

🎯 Part 10: Your First Real Project

Let's build a Mood Tracker Bot:

```ruby
require 'telegem'

bot = Telegem.new(ENV['BOT_TOKEN'])

bot.command('start') do |ctx|
  ctx.reply "Welcome to MoodTracker! 📊"
  ctx.reply "How are you feeling?"
  
  keyboard = Telegem::Markup.keyboard do
    row "😊 Happy", "😢 Sad", "😡 Angry"
    row "😴 Tired", "🤔 Thoughtful", "🎉 Excited"
  end
  
  ctx.reply "Choose your mood:", reply_markup: keyboard
end

bot.on(:message) do |ctx|
  next if ctx.message.command?
  
  mood = ctx.message.text
  ctx.session[:moods] ||= []
  ctx.session[:moods] << { mood: mood, time: Time.now }
  
  ctx.reply "Noted: #{mood}"
  ctx.reply "You've logged #{ctx.session[:moods].size} moods today!"
end

bot.command('stats') do |ctx|
  moods = ctx.session[:moods] || []
  
  if moods.empty?
    ctx.reply "No moods logged yet!"
  else
    # Count each mood
    counts = moods.group_by { |m| m[:mood] }
                  .transform_values(&:size)
    
    stats = counts.map { |mood, count| "#{mood}: #{count}x" }.join("\n")
    ctx.reply "Your mood stats:\n#{stats}"
  end
end

bot.start_polling
```

What this bot teaches you:

· ✅ Commands (/start, /stats)
· ✅ Keyboards (mood selection)
· ✅ Sessions (storing mood history)
· ✅ Data processing (counting moods)

---

📚 Part 11: Where to Go From Here

You've Learned:

· ✅ Basics - Creating bots, sending messages
· ✅ Interaction - Keyboards, buttons, commands
· ✅ Memory - Sessions, multi-step conversations
· ✅ Structure - Middleware, error handling
· ✅ Deployment - Polling vs webhooks

Next Steps:

Level 1: Beginner (You are here!)

· Build the Mood Tracker bot above
· Add 2 more commands
· Try adding a keyboard

Level 2: Intermediate

· Create a scene for something (quiz, survey, game)
· Add file upload support (photos, documents)
· Store data in a database (SQLite, PostgreSQL)

Level 3: Advanced

· Create your own middleware
· Add webhook support with SSL
· Build a plugin system

📖 Recommended Learning Path:

1. Week 1: Build 3 simple bots (echo, counter, menu)
2. Week 2: Add sessions to remember things
3. Week 3: Create a scene (quiz or order form)
4. Week 4: Deploy to a server (Heroku, Render)

---

🆘 Getting Help

When You're Stuck:

1. Check the error message - It often tells you what's wrong
2. Add puts statements - See what's happening step by step
3. Simplify - Remove code until it works, then add back
4. Ask for help - Community is there for you!

Resources:

· This guide - Bookmark it!
· API Reference - For all methods and options
· Example bots - In the examples/ folder
· GitLab Issues - Ask questions, report bugs

---

✨ Final Words of Encouragement

Remember:

1. Every expert was once a beginner - The Telegraf.js creator started just like you
2. Bugs are normal - Even big projects have them
3. Progress, not perfection - Each bot you build makes you better
4. You found this - That means you can definitely use it! 🎉

Your First Mission:

```ruby
# Right now, create this file and run it
# bot_mission.rb
require 'telegem'

bot = Telegem.new('YOUR_TOKEN')

bot.command('mission') do |ctx|
  ctx.reply "🎯 Mission accomplished!"
  ctx.reply "You just built and ran your first bot!"
  ctx.reply "Next: Try changing the message above."
end

bot.start_polling
```

Run it. See it work. You're a bot developer now! 🎊

---

📘 Ready for More?

For advanced topics, API details, and complex examples:

👉 Check out USAGE.md for advanced patterns!

---

Happy bot building! Remember: Every great bot started with a single /start command. Your journey has begun! 🚀
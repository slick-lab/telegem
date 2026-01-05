.md - Your Gateway to Telegram Bot Mastery

🌟 What is ctx?

Imagine you're at a coffee shop. The barista (ctx) is your connection to everything:

· Takes your order (message)
· Knows who you are (user info)
· Has your table number (chat info)
· Can bring you coffee (send replies)
· Remembers your usual (session data)

ctx is your barista for Telegram bots.

🎯 The 5 Essential Things ctx Gives You

1. Who's Talking? (ctx.from)

```ruby
# Every person has an ID card
user_id = ctx.from.id           # Like a social security number (unique!)
username = ctx.from.username    # @username (might be nil)
name = ctx.from.first_name      # "John"
full_name = ctx.from.full_name  # "John Doe" (first + last)

# Quick check:
if ctx.from.is_bot
  ctx.reply("Hey fellow bot! 🤖")
end
```

2. Where Are We? (ctx.chat)

```ruby
chat_id = ctx.chat.id           # Room number
room_type = ctx.chat.type       # "private", "group", "supergroup", "channel"

# Different rooms, different rules:
case ctx.chat.type
when "private"
  ctx.reply("Just us talking! 🤫")
when "group"
  ctx.reply("Hello everyone in the group! 👋")
end
```

3. What Was Said? (ctx.message)

```ruby
# The actual message
text = ctx.message.text         # What they typed
msg_id = ctx.message.message_id # Message ID (for editing/deleting)

# Was it a photo?
if ctx.message.photo
  ctx.reply("Nice photo! 📸")
end

# Was it a location?
if ctx.message.location
  lat = ctx.message.location.latitude
  lng = ctx.message.location.longitude
  ctx.reply("You're at #{lat}, #{lng}")
end
```

4. Did They Click a Button? (ctx.data)

```ruby
# Only works for inline button clicks
bot.on(:callback_query) do |ctx|
  # ctx.data contains what you put in callback_data
  case ctx.data
  when "pizza"
    ctx.reply("🍕 Pizza ordered!")
  when "burger"
    ctx.reply("🍔 Burger coming up!")
  end

  # ALWAYS answer callback queries!
  ctx.answer_callback_query(text: "Done!")
end
```

5. Remember Stuff (ctx.session & ctx.state)

```ruby
# ctx.session = Long-term memory (survives restarts)
ctx.session[:language] = "en"           # User prefers English
ctx.session[:pizza_count] ||= 0         # Start at 0, then increment
ctx.session[:pizza_count] += 1

# ctx.state = Short-term memory (current conversation)
ctx.state[:asking_for_name] = true      # Just for this flow
```

🚀 Your First 5 Minutes with ctx

Minute 1: Echo Bot

```ruby
bot.on(:message) do |ctx|
  # Whatever user says, repeat it back
  ctx.reply("You said: #{ctx.message.text}")
end
```

Minute 2: Welcome Bot

```ruby
bot.command('start') do |ctx|
  ctx.reply("Welcome #{ctx.from.first_name}! 🎉")
  ctx.reply("Your ID: #{ctx.from.id}")
  ctx.reply("Chat ID: #{ctx.chat.id}")
end
```

Minute 3: Memory Bot

```ruby
bot.command('count') do |ctx|
  # Count how many times user used /count
  ctx.session[:count] ||= 0
  ctx.session[:count] += 1
  ctx.reply("You've counted #{ctx.session[:count]} times!")
end
```

Minute 4: Smart Bot

```ruby
bot.hears(/hello|hi|hey/i) do |ctx|
  if ctx.chat.type == "private"
    ctx.reply("Hello there! 👋")
  else
    ctx.reply("Hello #{ctx.from.first_name}! 👋")
  end
end
```

Minute 5: Media Bot

```ruby
bot.command('cat') do |ctx|
  ctx.reply("Here's a cat! 🐱")
  ctx.photo("https://cataas.com/cat", caption: "Random cat!")
end
```

📦 The ctx Toolbox (25+ Methods)

Sending Messages

```ruby
# Text messages
ctx.reply("Hello!")                            # Basic
ctx.reply("*Bold text*", parse_mode: "Markdown") # Formatted
ctx.reply("<b>HTML bold</b>", parse_mode: "HTML") # HTML

# Replying to specific message
ctx.reply("Answering this", reply_to_message_id: 123)

# With keyboard at bottom
keyboard = Telegem.keyboard { row "Yes", "No" }
ctx.reply("Choose:", reply_markup: keyboard)
```

Sending Files & Media

```ruby
# Photo (from URL, file, or file_id)
ctx.photo("https://example.com/cat.jpg")
ctx.photo(File.open("cat.jpg"))
ctx.photo("AgACAx...")  # Telegram file_id

# With caption
ctx.photo("cat.jpg", caption: "My cat! 🐱")

# Document (PDF, etc.)
ctx.document("report.pdf", caption: "Monthly report")

# Audio, Video, Voice
ctx.audio("song.mp3", caption: "My song")
ctx.video("clip.mp4", caption: "Funny video!")
ctx.voice("message.ogg", caption: "Voice note")

# Location
ctx.location(51.5074, -0.1278)  # London coordinates
```

Managing Messages

```ruby
# Edit a message (need its message_id)
ctx.edit_message_text("Updated text!", message_id: 123)

# Delete messages
ctx.delete_message                    # Current message
ctx.delete_message(123)               # Specific message

# Forward/Copy messages
ctx.forward_message(source_chat_id, message_id)
ctx.copy_message(source_chat_id, message_id)

# Pin/Unpin
ctx.pin_message(message_id)
ctx.unpin_message
```

Interactive Features

```ruby
# Show "typing..." indicator
ctx.typing
# or
ctx.with_typing do
  # Long operation here
  sleep 2
  ctx.reply("Done thinking!")
end

# Show other actions
ctx.uploading_photo    # "uploading photo..."
ctx.uploading_document # "uploading document..."
```

Group Management (Bot needs admin)

```ruby
ctx.kick_chat_member(user_id)    # Remove from group
ctx.ban_chat_member(user_id)     # Ban user
ctx.unban_chat_member(user_id)   # Unban user

# Get info
admins = ctx.get_chat_administrators
member_count = ctx.get_chat_members_count
chat_info = ctx.get_chat
```

🎭 Real-World Scenarios

Scenario 1: Pizza Order

```ruby
bot.command('order') do |ctx|
  # Step 1: Ask for pizza type
  keyboard = ctx.keyboard do
    row "Margherita", "Pepperoni"
    row "Veggie", "Cancel"
  end

  ctx.reply("Choose pizza:", reply_markup: keyboard)
  ctx.state[:step] = "waiting_for_pizza"
end

# Handle the choice
bot.hears("Margherita") do |ctx|
  if ctx.state[:step] == "waiting_for_pizza"
    ctx.reply("🍕 Margherita selected!")
    ctx.reply("What's your address?")
    ctx.state[:step] = "waiting_for_address"
  end
end
```

Scenario 2: Quiz Game

```ruby
bot.command('quiz') do |ctx|
  ctx.session[:score] ||= 0

  inline = ctx.inline_keyboard do
    row button "Paris", callback_data: "answer_paris"
    row button "London", callback_data: "answer_london"
  end

  ctx.reply("Capital of France?", reply_markup: inline)
end

bot.on(:callback_query) do |ctx|
  if ctx.data == "answer_paris"
    ctx.session[:score] += 1
    ctx.answer_callback_query(text: "✅ Correct!")
    ctx.edit_message_text("🎉 Correct! Score: #{ctx.session[:score]}")
  else
    ctx.answer_callback_query(text: "❌ Wrong!")
  end
end
```

Scenario 3: Support Ticket

```ruby
bot.command('support') do |ctx|
  ctx.reply("Describe your issue:")
  ctx.state[:collecting_issue] = true
end

bot.on(:message) do |ctx|
  if ctx.state[:collecting_issue]
    issue = ctx.message.text
    # Save to database...
    ctx.reply("Ticket created! We'll contact you.")
    ctx.state.delete(:collecting_issue)
  end
end
```

⚠️ Common Mistakes & Fixes

Mistake 1: Assuming ctx.message always exists

```ruby
# ❌ WRONG
puts ctx.message.text  # Crashes if not a message update!

# ✅ RIGHT
if ctx.message && ctx.message.text
  puts ctx.message.text
end
```

Mistake 2: Forgetting to answer callbacks

```ruby
# ❌ WRONG (Telegram will show "loading...")
bot.on(:callback_query) do |ctx|
  ctx.reply("Button clicked!")
end

# ✅ RIGHT
bot.on(:callback_query) do |ctx|
  ctx.answer_callback_query  # Tell Telegram we handled it
  ctx.reply("Button clicked!")
end
```

Mistake 3: Not checking chat type

```ruby
# ❌ WRONG (might not work in channels)
ctx.reply("Hello!")

# ✅ RIGHT
if ctx.chat.type != "channel"
  ctx.reply("Hello!")
end
```

🎮 Interactive Learning Challenge

Build this in 10 minutes:

1. /hello - Replies with user's name
2. /dice - Rolls random number 1-6
3. /remember - Remembers what you say
4. /forget - Forgets everything
5. Buttons - Yes/No keyboard that works

```ruby
# Starter code - you finish it!
bot.command('hello') do |ctx|
  # Your code here
end

bot.command('dice') do |ctx|
  # Your code here (hint: rand(1..6))
end

bot.command('remember') do |ctx|
  # Store in ctx.session[:memory]
end
```

📚 Cheat Sheet

Want to... Use... Example
- Send text ctx.reply() ctx.reply("Hi!")
- Send photo ctx.photo() ctx.photo("cat.jpg")
- Get user ID ctx.from.id id = ctx.from.id
- Check chat type ctx.chat.type if ctx.chat.type == "private"
- Remember data ctx.session[] ctx.session[:count] = 5
- Temp data ctx.state[] ctx.state[:asking] = true
- Button clicks ctx.data if ctx.data == "yes"
- Edit message ctx.edit_message_text() - -ctx.edit_message_text("Updated!")

🚀 Next Steps Mastery Path

Week 1-2: Use everything in this guide
Week 3-4: Add keyboards and inline buttons
Week 5-6: Build multi-step scenes
Week 7-8: Add database persistence
Week 9-10: Deploy to cloud

---

Remember: ctx is your Swiss Army knife. The more you use it, the more natural it becomes. Start simple, build gradually, and soon you'll be building bots that feel magical! ✨

Your mission: Build one thing from this guide TODAY. Just one. Then build another tomorrow. Consistency beats complexity every time.
ctx - Your Complete Context Guide

Welcome to ctx, your Swiss Army knife for Telegram bot development! This guide balances quick understanding with detailed information.

📦 The Core Methods

ctx.reply()

Quick: Send messages with optional formatting and buttons.
In-depth: Wraps sendMessage API method with smart defaults.

```ruby
# Basic usage
ctx.reply("Hello!")  # Simple text

# With formatting
ctx.reply("*Bold* and _italic_", parse_mode: "Markdown")
ctx.reply("<b>HTML bold</b>", parse_mode: "HTML")

# With reply to message
ctx.reply("Answering this", reply_to_message_id: ctx.message.message_id)

# With keyboard
ctx.reply("Choose:", reply_markup: keyboard)
```

ctx.message

Quick: Access the current message.
In-depth: Returns a Message object or nil if not a message update.

```ruby
# Common properties
text = ctx.message.text           # Message content
msg_id = ctx.message.message_id   # Unique message identifier
date = ctx.message.date           # Unix timestamp
chat = ctx.message.chat           # Chat object

# Media properties (only present if applicable)
photo = ctx.message.photo         # Array of photo sizes
document = ctx.message.document   # Document object
location = ctx.message.location   # Location object
```

ctx.from

Quick: Get information about the message sender.
In-depth: Returns a User object with identity information.

```ruby
user_id = ctx.from.id            # Unique user identifier
username = ctx.from.username     # @username or nil
first_name = ctx.from.first_name # User's first name
last_name = ctx.from.last_name   # User's last name
full_name = ctx.from.full_name   # Combined first + last name
is_bot = ctx.from.is_bot         # Boolean (true for bot users)
```

ctx.chat

Quick: Information about where the conversation is happening.
In-depth: Returns a Chat object; always check for nil first.

```ruby
chat_id = ctx.chat.id            # Unique chat identifier
chat_type = ctx.chat.type        # "private", "group", "supergroup", or "channel"
chat_title = ctx.chat.title      # Group/channel title (nil for private)

# Safety first!
if ctx.chat
  ctx.reply("Chat ID: #{ctx.chat.id}")
else
  ctx.logger.warn("No chat object in this update")
end
```

ctx.data

Quick: Get callback data from inline button clicks.
In-depth: Only available for callback_query updates.

```ruby
bot.on(:callback_query) do |ctx|
  # Data from the clicked button
  button_data = ctx.data  # String set in callback_data
  
  # Always answer callback queries!
  ctx.answer_callback_query(text: "Clicked!")
  
  # Process based on data
  case ctx.data
  when "pizza"
    ctx.edit_message_text("🍕 Pizza ordered!")
  when "burger"
    ctx.edit_message_text("🍔 Burger coming up!")
  end
end

# 💡 PRO TIP: callback_data has 64-byte limit. Keep it short!
```

💾 Data Storage Methods

ctx.session - Persistent User Storage

Think of it as: User-specific memory that lasts between conversations.

```ruby
# Store data (survives bot restarts with proper store)
ctx.session[:language] = "en"
ctx.session[:preferences] = { theme: "dark", notifications: true }

# Retrieve data
lang = ctx.session[:language] || "en"  # Default if not set

# Complex data structures
ctx.session[:cart] ||= []
ctx.session[:cart] << { id: 1, name: "Pizza", quantity: 2 }

# Delete data
ctx.session.delete(:cart)

# 🚨 SECURITY WARNING: Never store sensitive data!
# ❌ BAD: ctx.session[:password] = "secret"
# ✅ GOOD: Store only user preferences, game state, etc.
```

ctx.state - Temporary Request Storage

Think of it as: Short-term memory for the current conversation flow.

```ruby
# Multi-step forms
ctx.state[:awaiting_email] = true
ctx.reply("What's your email address?")

# Later in another handler
if ctx.state[:awaiting_email]
  email = ctx.message.text
  # Validate email...
  ctx.state[:awaiting_email] = false
end

# 💡 Key difference from session:
# - state: Cleared after request (for step-by-step flows)
# - session: Persists (for user preferences)
```

ctx.match - Pattern Matching Results

Think of it as: Regex capture groups made easy.

```ruby
# Capture parts of messages
bot.hears(/order (\d+) (.+)/) do |ctx|
  quantity = ctx.match[1].to_i  # First capture: "3" → 3
  item = ctx.match[2]           # Second capture: "pizzas"
  
  ctx.reply("Ordering #{quantity} #{item}!")
end

# Multiple captures
bot.hears(/from (.+) to (.+)/) do |ctx|
  origin = ctx.match[1]  # "New York"
  destination = ctx.match[2]  # "Los Angeles"
end

# 💡 Works with: hears(), command() with regex, on() with text patterns
```

ctx.scene - Conversation Flow Management

Think of it as: Organized multi-step conversations.

```ruby
# Define a scene
bot.scene(:registration) do |scene|
  scene.enter do |ctx|
    ctx.reply("Welcome! What's your name?")
    ctx.session[:step] = :name
  end
  
  scene.on(:message) do |ctx|
    case ctx.session[:step]
    when :name
      ctx.session[:name] = ctx.message.text
      ctx.session[:step] = :email
      ctx.reply("Great! Now your email:")
    when :email
      ctx.session[:email] = ctx.message.text
      ctx.reply("Registration complete!")
      ctx.leave_scene
    end
  end
  
  scene.leave do |ctx|
    ctx.reply("Thank you for registering!")
    ctx.session.delete(:step)
  end
end

# Enter the scene
bot.command("register") do |ctx|
  ctx.enter_scene(:registration)
end
```

ctx.query - Inline Query Text

Think of it as: What users type after @yourbot.

```ruby
# Only works in inline mode
bot.on(:inline_query) do |ctx|
  search_term = ctx.query  # User's search text
  
  results = [
    {
      type: "article",
      id: "1",
      title: "Result for: #{search_term}",
      input_message_content: {
        message_text: "You searched: #{search_term}"
      }
    }
  ]
  
  ctx.answer_inline_query(results)
end
```

📸 Media Methods

File Sending Methods

```ruby
# Send photo
ctx.photo("image.jpg", caption: "Look at this!")
ctx.photo(photo_file_id)  # Reuse Telegram file ID

# Send document
ctx.document("report.pdf", caption: "Monthly report")

# Send audio
ctx.audio("song.mp3", performer: "Artist", title: "Song Title")

# Send video
ctx.video("clip.mp4", caption: "Check this out!")

# Send voice message
ctx.voice("message.ogg", caption: "Voice note")

# Send sticker
ctx.sticker("CAACAgIAAxk...")  # Sticker file_id

# Send location
ctx.location(51.5074, -0.1278)  # London coordinates
```

File Input Options

```ruby
# All accept multiple input types:
ctx.photo("path/to/file.jpg")           # File path
ctx.photo(File.open("image.jpg"))       # File object
ctx.photo(file_id_from_telegram)        # Telegram file ID
ctx.photo(StringIO.new(image_data))     # In-memory data
```

⌨️ Keyboard Methods

Reply Keyboards (Appear at bottom)

```ruby
# Create a keyboard
keyboard = ctx.keyboard do |k|
  k.button("Yes")
  k.button("No")
  k.row  # New row
  k.button("Maybe")
  k.button("Cancel")
end

# Send with keyboard
ctx.reply_with_keyboard("Choose option:", keyboard)

# Remove keyboard
ctx.remove_keyboard("Keyboard removed!")

# Keyboard options
keyboard = ctx.keyboard(resize: true, one_time: true) do |k|
  k.button("Option")
end
```

Inline Keyboards (Buttons in message)

```ruby
# Create inline keyboard
inline_kb = ctx.inline_keyboard do |k|
  k.button("Order Pizza", callback_data: "order_pizza")
  k.button("View Menu", url: "https://example.com/menu")
  k.button("Share", switch_inline_query: "Check this pizza place!")
end

# Send with inline keyboard
ctx.reply_with_inline_keyboard("What would you like?", inline_kb)

# Edit existing keyboard
ctx.edit_message_reply_markup(new_inline_kb)
```

⏳ Action Methods

Chat Actions (Typing indicators)

```ruby
# Show typing
ctx.typing  # Shows "typing..."

# Show upload status
ctx.uploading_photo    # "uploading photo..."
ctx.uploading_video    # "uploading video..."
ctx.uploading_document # "uploading document..."
ctx.uploading_audio    # "uploading audio..."

# Generic action
ctx.send_chat_action("choose_sticker")  # Any valid action

# Wrap long operations
ctx.with_typing do
  # Complex processing...
  sleep(2)
  ctx.reply("Done!")
end
```

✏️ Message Management

How to Get Message IDs for Editing

Important: To edit a message, you need its message_id. Here's the easiest way:

```ruby
# Method 1: Capture the ID right after sending
bot.command("editme") do |ctx|
  # Send a message first and capture the response
  response = ctx.reply("This will be edited in 2 seconds...")
  
  # Extract the message_id from the API response
  if response && response["ok"]
    message_id = response["result"]["message_id"]
    
    # Now you can edit it later
    sleep(2)
    ctx.edit_message_text("This is the edited text!", message_id: message_id)
  else
    ctx.reply("Failed to send message!")
  end
end

# 💡 PRO TIP: The response structure is:
# {
#   "ok": true,
#   "result": {
#     "message_id": 123,   # ← THIS IS WHAT YOU NEED!
#     "chat": {...},
#     "text": "..."
#   }
# }
```

Edit & Delete

```ruby
# Edit message text (requires message_id)
ctx.edit_message_text("Updated text!", message_id: message_id)
ctx.edit_message_text("New text", message_id: message_id, parse_mode: "HTML")

# Delete messages
ctx.delete_message  # Delete the current message (if triggered by message)
ctx.delete_message(specific_message_id)  # Delete any message by ID

# Pin/unpin messages
ctx.pin_message(message_id)    # Pin to chat
ctx.unpin_message              # Unpin from chat
ctx.unpin_message(message_id)  # Unpin specific message
```

Practical Editing Example

```ruby
# Progressive editing example
bot.command("countdown") do |ctx|
  # Send initial message
  response = ctx.reply("Starting countdown...")
  return unless response["ok"]
  
  message_id = response["result"]["message_id"]
  
  # Edit it multiple times
  3.downto(1) do |num|
    sleep(1)
    ctx.edit_message_text("#{num}...", message_id: message_id)
  end
  
  sleep(1)
  ctx.edit_message_text("🎉 Blast off!", message_id: message_id)
end

# Store and edit later
bot.command("setreminder") do |ctx|
  # Send reminder message
  response = ctx.reply("Reminder set for 5 seconds from now...")
  return unless response["ok"]
  
  # Store the message ID in session
  ctx.session[:reminder_message_id] = response["result"]["message_id"]
  
  # Schedule edit (in real app, use background job)
  Thread.new do
    sleep(5)
    # You'd need to retrieve context somehow here
    # Real implementation would use a job queue
  end
end
```

Forward & Copy

```ruby
# Forward message
ctx.forward_message(source_chat_id, message_id)

# Copy message (keeps formatting)
ctx.copy_message(source_chat_id, message_id)

# Both support options
ctx.forward_message(
  source_chat_id,
  message_id,
  disable_notification: true
)
```

👥 Group Management

Member Management

```ruby
# Requires bot admin permissions!
ctx.kick_chat_member(user_id)      # Remove from group
ctx.ban_chat_member(user_id)       # Ban permanently
ctx.unban_chat_member(user_id)     # Remove ban

# With options
ctx.ban_chat_member(
  user_id,
  until_date: Time.now + 86400,  # 24-hour ban
  revoke_messages: true          # Delete user's messages
)
```

Chat Information

```ruby
# Get chat details
chat_info = ctx.get_chat
# Returns: {id, type, title, username, etc.}

# Get administrators
admins = ctx.get_chat_administrators
# Array of ChatMember objects

# Member count
count = ctx.get_chat_members_count
```

🔧 Utility Methods

Command Helpers

```ruby
# Check if message is a command
if ctx.command?
  ctx.reply("I see a command!")
end

# Get command arguments
# User sends: /search funny cats
args = ctx.command_args  # "funny cats"
```

API & Logging

```ruby
# Direct API access (advanced)
ctx.api.call('sendMessage', chat_id: 123, text: "Direct call")

# Logging
ctx.logger.info("User #{ctx.from.id} said hello")
ctx.logger.error("Something went wrong!", error: e)

# Raw update (debugging)
puts ctx.raw_update  # Original Telegram JSON

# User ID shortcut
user_id = ctx.user_id  # Same as ctx.from.id
```

🎯 Best Practices

1. Always Check for Nil

```ruby
# Safe access pattern
if ctx.chat && ctx.chat.type == "private"
  # Handle private chat
end

# Ruby 2.3+ safe navigation
title = ctx.chat&.title || "Unknown"
```

2. Handle Different Update Types

```ruby
bot.on(:message) do |ctx|
  # Handle messages
end

bot.on(:callback_query) do |ctx|
  # Handle button clicks (ALWAYS answer!)
  ctx.answer_callback_query
end

bot.on(:inline_query) do |ctx|
  # Handle @bot queries
  ctx.answer_inline_query(results)
end
```

3. Error Handling

```ruby
begin
  ctx.reply(some_message)
rescue => e
  ctx.logger.error("Failed to send: #{e.message}")
  # Optionally notify user
  ctx.reply("Sorry, something went wrong!")
end
```

4. Performance Tips

```ruby
# Use sessions wisely
ctx.session[:data] = large_data  # ❌ Avoid huge data
ctx.session[:count] = 123        # ✅ Store simple data

# Clean up state
ctx.state.clear  # When done with multi-step process

# Use file IDs for repeated media
# First send gets file_id, reuse it!
photo_file_id = ctx.message.photo.last.file_id
ctx.session[:last_photo] = photo_file_id
```

📚 Quick Reference

Method Best For When to Use
ctx.session User preferences, game state, shopping carts Data that should persist
ctx.state Multi-step forms, temporary flags Within a single conversation
ctx.match Parsing commands with arguments Regex pattern matching
ctx.scene Complex conversations Registration, surveys, workflows
ctx.reply_with_keyboard Multiple choice, menus When you need user selection
ctx.reply_with_inline_keyboard Interactive messages Actions without leaving chat

Remember: ctx is your interface to everything Telegram. Use it wisely, and your bot will shine! 🌟
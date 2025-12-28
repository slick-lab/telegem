```markdown
# Context API Reference

The `Telegem::Core::Context` object provides access to the current update and helper methods for responding.

## Accessing Update Data

### Basic Accessors

```ruby
ctx.update        # Raw Telegem::Types::Update object
ctx.message       # Current message (Telegem::Types::Message)
ctx.callback_query # Callback query object
ctx.inline_query  # Inline query object
ctx.from          # User who sent the update (Telegem::Types::User)
ctx.chat          # Chat where update originated (Telegem::Types::Chat)
ctx.data          # Callback query data (String)
ctx.query         # Inline query text (String)
ctx.state         # Hash for temporary state storage
ctx.session       # Persistent session storage (Hash)
ctx.match         # Regex match data from `hears` or `command`
```

Common Patterns

```ruby
# Check message type
if ctx.message.text
  puts "Text message: #{ctx.message.text}"
end

# Get user info
user_id = ctx.from.id
username = ctx.from.username
full_name = ctx.from.full_name  # "John Doe"

# Get chat info
chat_id = ctx.chat.id
chat_type = ctx.chat.type  # "private", "group", "supergroup", "channel"

# Check if callback query
if ctx.callback_query
  puts "Button clicked: #{ctx.data}"
end
```

Message Sending Methods

reply(text, **options)

Sends a text message to the current chat.

```ruby
ctx.reply("Hello World!")
ctx.reply("Formatted text", parse_mode: "HTML")
ctx.reply("With reply", reply_to_message_id: ctx.message.message_id)

# With keyboard
keyboard = Telegem.keyboard { row "Yes", "No" }
ctx.reply("Choose one:", reply_markup: keyboard)
```

Options:

· parse_mode: "Markdown", "HTML", or "MarkdownV2"
· reply_to_message_id: Reply to specific message
· reply_markup: Keyboard or inline markup
· disable_web_page_preview: Boolean
· disable_notification: Boolean

Media Methods

photo(photo, caption: nil, **options)

Sends a photo.

```ruby
# From URL
ctx.photo("https://example.com/image.jpg")

# From local file
ctx.photo(File.open("image.jpg"))

# With caption
ctx.photo("image.jpg", caption: "Nice photo!")

# With custom options
ctx.photo("image.jpg", 
  caption: "Sunset",
  parse_mode: "HTML",
  disable_notification: true
)
```

document(document, caption: nil, **options)

Sends a document.

```ruby
ctx.document(File.open("report.pdf"), caption: "Monthly report")
```

audio(audio, caption: nil, **options)

Sends an audio file.

```ruby
ctx.audio(File.open("song.mp3"), caption: "My song")
```

video(video, caption: nil, **options)

Sends a video.

```ruby
ctx.video(File.open("video.mp4"), caption: "Funny cat")
```

voice(voice, caption: nil, **options)

Sends a voice message.

```ruby
ctx.voice(File.open("voice.ogg"), caption: "My voice")
```

sticker(sticker, **options)

Sends a sticker.

```ruby
ctx.sticker("CAACAgIAAxkBAAIB")
```

location(latitude, longitude, **options)

Sends a location.

```ruby
ctx.location(40.7128, -74.0060)  # New York
ctx.location(51.5074, -0.1278, live_period: 3600)  # Live location for 1 hour
```

Message Editing Methods

edit_message_text(text, **options)

Edits text of a message.

```ruby
ctx.edit_message_text("Updated text")
ctx.edit_message_text("New text <b>bold</b>", parse_mode: "HTML")
```

edit_message_reply_markup(reply_markup, **options)

Edits only the reply markup of a message.

```ruby
new_keyboard = Telegem.inline do
  row button "New Button", callback_data: "new"
end
ctx.edit_message_reply_markup(new_keyboard)
```

Message Management

delete_message(message_id = nil)

Deletes a message.

```ruby
ctx.delete_message                    # Delete current message
ctx.delete_message(123)              # Delete specific message
```

forward_message(from_chat_id, message_id, **options)

Forwards a message.

```ruby
ctx.forward_message(-100123456789, 42)  # From channel to current chat
```

copy_message(from_chat_id, message_id, **options)

Copies a message.

```ruby
ctx.copy_message(-100123456789, 42, caption: "Copied!")
```

pin_message(message_id, **options)

Pins a message.

```ruby
ctx.pin_message(ctx.message.message_id)
ctx.pin_message(123, disable_notification: true)
```

unpin_message(**options)

Unpins a message.

```ruby
ctx.unpin_message
ctx.unpin_message(message_id: 123)  # Unpin specific message
```

Chat Actions

send_chat_action(action, **options)

Shows a chat action (typing, uploading, etc.).

```ruby
ctx.send_chat_action('typing')
ctx.send_chat_action('upload_photo')
```

Available actions:

· typing
· upload_photo
· record_video
· upload_video
· record_audio
· upload_audio
· upload_document
· find_location
· record_video_note
· upload_video_note

Convenience Methods

```ruby
ctx.typing                    # Same as send_chat_action('typing')
ctx.uploading_photo           # Same as send_chat_action('upload_photo')
ctx.uploading_video           # Same as send_chat_action('upload_video')
ctx.uploading_audio           # Same as send_chat_action('upload_audio')
ctx.uploading_document        # Same as send_chat_action('upload_document')
```

with_typing(&block)

Wraps code block with typing indicator.

```ruby
ctx.with_typing do
  # Long operation
  sleep 2
  ctx.reply("Done!")
end
```

Inline Query Responses

answer_callback_query(text: nil, show_alert: false, **options)

Answers a callback query (inline button click).

```ruby
ctx.answer_callback_query(text: "Button clicked!")
ctx.answer_callback_query(text: "Error!", show_alert: true)
ctx.answer_callback_query(url: "https://example.com")  # Open URL
```

answer_inline_query(results, **options)

Answers an inline query.

```ruby
results = [
  {
    type: "article",
    id: "1",
    title: "Result 1",
    input_message_content: { message_text: "You selected 1" }
  }
]

ctx.answer_inline_query(results, cache_time: 300)
```

Chat Management

kick_chat_member(user_id, **options)

Kicks a user from the chat.

```ruby
ctx.kick_chat_member(123456789)
ctx.kick_chat_member(123456789, until_date: Time.now + 86400)  # 24 hour ban
```

ban_chat_member(user_id, **options)

Bans a user from the chat.

```ruby
ctx.ban_chat_member(123456789)
```

unban_chat_member(user_id, **options)

Unbans a user.

```ruby
ctx.unban_chat_member(123456789)
```

get_chat_administrators(**options)

Gets chat administrators.

```ruby
admins = ctx.get_chat_administrators
admins.each { |admin| puts admin.user.username }
```

get_chat_members_count(**options)

Gets chat member count.

```ruby
count = ctx.get_chat_members_count
ctx.reply("Chat has #{count} members")
```

get_chat(**options)

Gets chat information.

```ruby
chat_info = ctx.get_chat
ctx.reply("Chat title: #{chat_info['title']}")
```

Keyboard Helpers

keyboard(&block)

Creates a reply keyboard.

```ruby
kb = ctx.keyboard do
  row "Button 1", "Button 2"
  row request_location("Share Location")
end
ctx.reply("Choose:", reply_markup: kb)
```

inline_keyboard(&block)

Creates an inline keyboard.

```ruby
kb = ctx.inline_keyboard do
  row button "Visit", url: "https://example.com"
  row button "Select", callback_data: "selected"
end
ctx.reply("Options:", reply_markup: kb)
```

reply_with_keyboard(text, keyboard_markup, **options)

Sends a message with reply keyboard.

```ruby
keyboard = Telegem.keyboard { row "Yes", "No" }
ctx.reply_with_keyboard("Do you agree?", keyboard)
```

reply_with_inline_keyboard(text, inline_markup, **options)

Sends a message with inline keyboard.

```ruby
inline = Telegem.inline { row button "Click", callback_data: "click" }
ctx.reply_with_inline_keyboard("Click button:", inline)
```

remove_keyboard(text = nil, **options)

Removes reply keyboard.

```ruby
ctx.remove_keyboard("Keyboard removed")  # Sends message
# or
markup = ctx.remove_keyboard  # Returns markup for later use
```

Scene Management

enter_scene(scene_name, **options)

Enters a scene (multi-step conversation).

```ruby
ctx.enter_scene(:survey)
ctx.enter_scene(:order, step: :select_product)
```

leave_scene(**options)

Leaves current scene.

```ruby
ctx.leave_scene
```

current_scene

Returns current scene object.

```ruby
scene = ctx.current_scene
ctx.reply("Current step: #{scene.current_step(ctx)}")
```

Command Utilities

command?

Checks if current message is a command.

```ruby
if ctx.command?
  ctx.reply("That's a command!")
end
```

command_args

Gets command arguments.

```ruby
# For "/greet John"
bot.command('greet') do |ctx|
  name = ctx.command_args  # => "John"
  ctx.reply("Hello #{name}!")
end
```

Utility Methods

logger

Access bot logger.

```ruby
ctx.logger.info("Processing message from #{ctx.from.id}")
ctx.logger.error("Something went wrong!")
```

api

Access raw API client.

```ruby
# Direct API call
result = ctx.api.call!('getMe')
ctx.reply("Bot username: #{result['username']}")
```

user_id

Shortcut for user ID.

```ruby
user_id = ctx.user_id  # Same as ctx.from.id
```

raw_update

Gets raw update data.

```ruby
update_json = ctx.raw_update.to_json
File.write('update.json', update_json)
```

Complete Example

```ruby
bot.command('info') do |ctx|
  # Show typing indicator
  ctx.typing
  
  # Gather info
  user = ctx.from
  chat = ctx.chat
  
  # Create response
  text = <<~INFO
    👤 User Info:
    ID: #{user.id}
    Name: #{user.full_name}
    Username: @#{user.username}
    
    💬 Chat Info:
    ID: #{chat.id}
    Type: #{chat.type}
    Title: #{chat.title}
    
    📊 Members: #{ctx.get_chat_members_count}
  INFO
  
  # Send with inline keyboard
  keyboard = ctx.inline_keyboard do
    row button "Refresh", callback_data: "refresh_info"
    row button "Close", callback_data: "close"
  end
  
  ctx.reply(text, reply_markup: keyboard)
end

# Handle refresh button
bot.on(:callback_query, data: "refresh_info") do |ctx|
  ctx.answer_callback_query(text: "Refreshing...")
  ctx.edit_message_text("Info refreshed at #{Time.now}")
end
```

---

Previous: Bot Methods | Next: Keyboard API

```
```
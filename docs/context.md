# Context Object (ctx)

The Context object is the heart of every Telegem bot handler. It encapsulates the current update and provides methods to interact with Telegram's API.

## Overview

Every handler receives a `ctx` (context) parameter containing:

- Current update information
- Bot instance reference
- User and chat data
- Session data
- Response methods
- Utility helpers

## Core Properties

### Update Information

```ruby
ctx.update        # Raw Update object (Telegem::Types::Update)
ctx.update_id     # Unique update identifier
ctx.update_type   # :message, :callback_query, :inline_query, etc.
```

### Bot Reference

```ruby
ctx.bot          # Bot instance
ctx.api          # Direct API client access
ctx.logger       # Bot's logger
```

### State Management

```ruby
ctx.state        # Temporary state (cleared after handler)
ctx.session      # Persistent user session
ctx.match        # Regex match data from hears/command
ctx.scene        # Current scene data
```

## User and Chat Information

### User Data

```ruby
ctx.from              # User object (Telegem::Types::User)
ctx.from.id           # User ID (integer)
ctx.from.username     # Username (string, may be nil)
ctx.from.first_name   # First name
ctx.from.last_name    # Last name (may be nil)
ctx.from.language_code # User's language ('en', 'es', etc.)
ctx.from.is_bot       # Boolean: is this user a bot?
ctx.from.is_premium   # Boolean: has Telegram Premium?

# Convenience methods
ctx.user_id           # Shortcut for ctx.from&.id
```

### Chat Data

```ruby
ctx.chat              # Chat object (Telegem::Types::Chat)
ctx.chat.id           # Chat ID
ctx.chat.type         # 'private', 'group', 'supergroup', 'channel'
ctx.chat.title        # Chat title (for groups/channels)
ctx.chat.username     # Chat username (for public chats)

# Type checking
ctx.chat.private?     # Is private chat?
ctx.chat.group?       # Is group?
ctx.chat.supergroup?  # Is supergroup?
ctx.chat.channel?     # Is channel?
```

## Message Access

### Basic Message Properties

```ruby
ctx.message                # Message object (Telegem::Types::Message)
ctx.message.message_id     # Message ID
ctx.message.date           # Send date (Time object)
ctx.message.edit_date      # Edit date (Time object, if edited)
ctx.message.text           # Message text
ctx.message.caption        # Media caption

# Convenience shortcuts
ctx.text                   # ctx.message&.text
ctx.caption                # ctx.message&.caption
ctx.message_id             # ctx.message&.message_id
```

### Message Metadata

```ruby
ctx.message.from           # Sender (same as ctx.from)
ctx.message.chat           # Chat (same as ctx.chat)
ctx.message.reply_to_message # Replied-to message
ctx.message.forward_from   # Original sender (if forwarded)
ctx.message.entities       # Text formatting entities
ctx.message.caption_entities # Caption formatting entities
```

### Reply Information

```ruby
ctx.reply?                 # Is this a reply?
ctx.replied_message        # Message being replied to
ctx.replied_text           # Text of replied message
ctx.replied_from           # User who sent replied message
ctx.replied_chat           # Chat of replied message
```

### Command Processing

```ruby
ctx.command?               # Is message a command?
ctx.command_name           # Command name ('start', 'help')
ctx.command_args           # Arguments string after command

# Example: /ban @user reason
ctx.command_name           # => 'ban'
ctx.command_args           # => '@user reason'
```

### Media Detection

```ruby
ctx.has_media?             # Has any media attachment?
ctx.media_type             # :photo, :document, :audio, :video, :voice, :sticker

# Specific media
ctx.message.photo          # Array of PhotoSize objects
ctx.message.document       # Document object
ctx.message.audio          # Audio object
ctx.message.video          # Video object
ctx.message.voice          # Voice object
ctx.message.sticker        # Sticker object
ctx.message.animation      # Animation object
ctx.message.video_note     # VideoNote object
```

## Update Type Detection

### Callback Queries

```ruby
ctx.callback_query?        # Is callback query update?
ctx.callback_query         # CallbackQuery object
ctx.data                   # Callback data string
```

### Inline Queries

```ruby
ctx.inline_query?          # Is inline query update?
ctx.inline_query           # InlineQuery object
ctx.query                  # Search query string
```

### Other Update Types

```ruby
ctx.poll?                  # Poll update
ctx.poll_answer?           # Poll answer update
ctx.chat_member?           # Chat member update
ctx.my_chat_member?        # Bot's membership update
ctx.chat_join_request?     # Join request update
```

## Sending Messages

### Basic Text Replies

```ruby
ctx.reply("Hello world!")
ctx.reply("Hello", parse_mode: "Markdown")
ctx.reply("Hello", disable_web_page_preview: true)
ctx.reply("Hello", reply_to_message_id: 123)
```

### Media Messages

```ruby
# Photos
ctx.photo("https://example.com/image.jpg")
ctx.photo(File.open("local.jpg"))
ctx.photo(file_id, caption: "Caption")

# Documents
ctx.document("file.pdf", caption: "Report")
ctx.document(File.open("report.pdf"))

# Audio/Video
ctx.audio("song.mp3", title: "Song", performer: "Artist")
ctx.video("video.mp4", caption: "Video")
ctx.voice("voice.ogg")
ctx.sticker(sticker_file_id)
```

### Location and Contact

```ruby
ctx.location(37.7749, -122.4194)  # Latitude, longitude
ctx.contact("+1234567890", "John", last_name: "Doe")
```

### Chat Actions

```ruby
ctx.typing
ctx.uploading_photo
ctx.uploading_video
ctx.uploading_document
ctx.find_location
ctx.record_video
ctx.record_audio
```

## Keyboard Markup

### Reply Keyboards

```ruby
keyboard = Telegem.keyboard do
  row "Button 1", "Button 2"
  row "Button 3"
end.resize.one_time

ctx.reply("Choose:", reply_markup: keyboard)
```

### Inline Keyboards

```ruby
inline = Telegem.inline do
  row callback("Yes", "yes"), callback("No", "no")
  row url("Visit", "https://example.com")
end

ctx.reply("Confirm?", reply_markup: inline)
```

### Removing Keyboards

```ruby
ctx.remove_keyboard
ctx.remove_keyboard("Done!")
ctx.remove_keyboard(selective: true)
```

## Message Editing

```ruby
ctx.edit_message_text("New text")
ctx.edit_message_text("New text", message_id: 123)
ctx.edit_message_caption("New caption")
ctx.edit_message_reply_markup(new_keyboard)
```

## Message Deletion

```ruby
ctx.delete_message          # Delete current message
ctx.delete_message(123)     # Delete specific message
```

## Callback Query Responses

```ruby
ctx.answer_callback_query("Done!")
ctx.answer_callback_query("Error!", show_alert: true)
ctx.answer_callback_query(url: "https://example.com")
```

## Inline Query Responses

```ruby
results = [
  Telegem::Types::InlineQueryResultArticle.new(
    id: "1",
    title: "Article",
    input_message_content: { message_text: "Content" }
  )
]

ctx.answer_inline_query(results)
```

## File Operations

```ruby
# Download files
ctx.download_file(file_id)                    # Returns content
ctx.download_file(file_id, "path/to/file")    # Saves to file

# Get file info
file_info = ctx.api.call('getFile', file_id: file_id)
file_path = file_info['file_path']
```

## Chat Management

### Member Management

```ruby
ctx.kick_chat_member(user_id)
ctx.ban_chat_member(user_id, until_date: future_time)
ctx.unban_chat_member(user_id)
ctx.restrict_chat_member(user_id, permissions: { can_send_messages: false })
ctx.promote_chat_member(user_id, can_invite_users: true)
```

### Chat Information

```ruby
admins = ctx.get_chat_administrators
member = ctx.get_chat_member(user_id)
count = ctx.get_chat_members_count
chat_info = ctx.get_chat
```

### Message Pinning

```ruby
ctx.pin_message(message_id)
ctx.unpin_message(message_id)
ctx.unpin_all_messages
```

## Forwarding and Copying

```ruby
ctx.forward_message(from_chat_id, message_id)
ctx.copy_message(from_chat_id, message_id, caption: "New caption")
```

## Scene Management

```ruby
ctx.enter_scene(:scene_name)
ctx.leave_scene
ctx.leave_scene(reason: :completed)
ctx.in_scene?
ctx.current_scene
ctx.scene_data
ctx.ask("Question?")
ctx.next_step
ctx.next_step(:specific_step)
```

## Session Management

```ruby
# Store data
ctx.session[:user_data] = "value"
ctx.session[:preferences] = { theme: "dark" }

# Retrieve data
data = ctx.session[:user_data]
prefs = ctx.session[:preferences]

# Modify data
ctx.session[:counter] ||= 0
ctx.session[:counter] += 1

# Clean up
ctx.session.delete(:temp_key)
ctx.session.clear
```

## Polls

```ruby
ctx.send_poll("Question?", ["Option 1", "Option 2"])
ctx.stop_poll(message_id)
```

## Web Apps

```ruby
ctx.web_app_data  # Data from web app interactions
```

## Advanced Usage

### Conditional Responses

```ruby
if ctx.chat.private?
  ctx.reply("This is private")
elsif ctx.chat.group?
  ctx.reply("This is a group", reply_to_message_id: ctx.message_id)
end
```

### Error Handling in Handlers

```ruby
bot.command('process') do |ctx|
  begin
    # Process something risky
    result = process_data(ctx.text)
    ctx.reply("Result: #{result}")
  rescue => e
    ctx.logger.error("Processing error: #{e.message}")
    ctx.reply("Sorry, processing failed. Try again.")
  end
end
```

### Complex Keyboard Building

```ruby
keyboard = Telegem.keyboard do
  row "📅 Today", "📅 Tomorrow"
  row "⚙️ Settings", "❓ Help"
  request_location "📍 Location"
  request_contact "📞 Contact"
end.resize.selective

ctx.reply("What would you like to do?", reply_markup: keyboard)
```

### Session-Based Personalization

```ruby
bot.command('start') do |ctx|
  ctx.session[:name] ||= ctx.from.first_name
  ctx.session[:visit_count] ||= 0
  ctx.session[:visit_count] += 1

  greeting = if ctx.session[:visit_count] == 1
    "Welcome, #{ctx.session[:name]}!"
  else
    "Welcome back, #{ctx.session[:name]}! (Visit ##{ctx.session[:visit_count]})"
  end

  ctx.reply(greeting)
end
```

## Edge Cases and Error Handling

### Missing Data

```ruby
# Handle missing user
if ctx.from
  ctx.reply("Hello #{ctx.from.first_name}")
else
  ctx.reply("Hello anonymous user")
end

# Handle missing message text
text = ctx.text || "no text"
ctx.reply("You said: #{text}")
```

### Media Validation

```ruby
bot.on(:message) do |ctx|
  if ctx.has_media?
    case ctx.media_type
    when :photo
      ctx.reply("Nice photo!")
    when :document
      if ctx.message.document.mime_type&.start_with?('application/pdf')
        ctx.reply("PDF received")
      else
        ctx.reply("Unsupported document type")
      end
    else
      ctx.reply("Unsupported media type")
    end
  end
end
```

### Rate Limiting

```ruby
bot.use do |ctx, next_middleware|
  user_id = ctx.from&.id
  if user_id
    # Implement rate limiting logic
    # ...
  end
  next_middleware.call(ctx)
end
```

### Large Messages

Telegram has limits:
- Text messages: 4096 characters
- Captions: 1024 characters
- Handle truncation:

```ruby
def truncate_text(text, max_length = 4000)
  if text.length > max_length
    text[0...max_length] + "..."
  else
    text
  end
end

ctx.reply(truncate_text(long_text))
```

### File Size Limits

```ruby
bot.document do |ctx|
  doc = ctx.message.document
  if doc.file_size > 50 * 1024 * 1024  # 50MB
    ctx.reply("File too large (max 50MB)")
  else
    # Process file
  end
end
```

### Timeouts and Async Operations

```ruby
bot.command('long_process') do |ctx|
  ctx.reply("Processing...")

  # For long operations, use async
  Async do
    result = long_running_task(ctx.text)
    ctx.reply("Done: #{result}")
  end
end
```

## Best Practices

1. **Always check for nil values** before accessing properties
2. **Use convenience methods** when available (ctx.text vs ctx.message&.text)
3. **Handle errors gracefully** in handlers
4. **Validate user input** before processing
5. **Use sessions sparingly** and with TTL
6. **Implement rate limiting** for intensive operations
7. **Log important actions** for debugging
8. **Test with different update types** and edge cases

The Context object is your primary interface to Telegram's API. Understanding its properties and methods is essential for building robust bots.</content>
<parameter name="filePath">/home/slick/telegem/docs/context.md
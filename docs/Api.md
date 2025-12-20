
# 📚 API Reference

Quick reference for all Telegem classes and methods. Use this when you know what you need and want the exact syntax.

---

## 📦 Main Classes

### `Telegem::Bot` (Main Class)
```ruby
# Create a bot
bot = Telegem.new(token)
# or
bot = Telegem::Core::Bot.new(token, **options)

# Options:
# - logger: Custom logger (default: Logger.new($stdout))
# - concurrency: Max parallel updates (default: 10)
# - session_store: :memory, :redis, or custom object
```

Context (ctx in handlers)

The object you get in every handler. Controls the conversation.

---

🎮 Context Methods

Sending Messages

```ruby
ctx.reply(text, **options)                    # Send message
ctx.edit_message_text(text, **options)        # Edit last message
ctx.delete_message(message_id = nil)          # Delete message
ctx.forward_message(from_chat_id, message_id) # Forward message
ctx.copy_message(from_chat_id, message_id)    # Copy message
```

Sending Media

```ruby
ctx.photo(photo, caption: nil, **options)     # Send photo
ctx.document(doc, caption: nil, **options)    # Send file
ctx.audio(audio, caption: nil, **options)     # Send audio
ctx.video(video, caption: nil, **options)     # Send video
ctx.voice(voice, caption: nil, **options)     # Send voice
ctx.sticker(sticker, **options)               # Send sticker
ctx.location(lat, long, **options)            # Send location
```

Chat Actions

```ruby
ctx.send_chat_action(action, **options)       # Show typing/uploading
ctx.typing(**options)                         # Shortcut for 'typing'
ctx.uploading_photo(**options)                # Shortcut for 'upload_photo'
ctx.with_typing { block }                     # Show typing while block runs
```

Callback & Inline Queries

```ruby
ctx.answer_callback_query(text: nil, show_alert: false)
ctx.answer_inline_query(results, **options)
```

Chat Management

```ruby
ctx.get_chat(**options)
ctx.get_chat_administrators(**options)
ctx.get_chat_members_count(**options)
ctx.ban_chat_member(user_id, **options)
ctx.unban_chat_member(user_id, **options)
ctx.kick_chat_member(user_id, **options)
ctx.pin_message(message_id, **options)
ctx.unpin_message(**options)
```

Keyboard Helpers

```ruby
ctx.keyboard { block }                        # Create reply keyboard
ctx.inline_keyboard { block }                 # Create inline keyboard
ctx.reply_with_keyboard(text, keyboard, **options)
ctx.reply_with_inline_keyboard(text, inline, **options)
ctx.remove_keyboard(text = nil, **options)
ctx.edit_message_reply_markup(reply_markup, **options)
```

Scene Management

```ruby
ctx.enter_scene(scene_name, **options)
ctx.leave_scene(**options)
ctx.current_scene                             # Returns current scene object
```

Information Getters

```ruby
ctx.message                                   # Message object
ctx.callback_query                            # CallbackQuery object
ctx.inline_query                              # InlineQuery object
ctx.from                                      # User who sent
ctx.chat                                      # Chat object
ctx.data                                      # Callback data (for buttons)
ctx.query                                     # Inline query text
ctx.user_id                                   # Shortcut for from.id
ctx.command?                                  # true if message is command
ctx.command_args                              # Arguments after command
ctx.raw_update                                # Raw Telegram JSON
ctx.api                                       # Direct API client access
ctx.logger                                    # Bot's logger
ctx.session                                   # User's session hash
ctx.state                                     # Temporary state hash
ctx.match                                     # Regex match data
```

---

⌨️ Keyboard Builders

Reply Keyboard

```ruby
keyboard = Telegem::Markup.keyboard do
  row "Button 1", "Button 2"
  row "Cancel"
end

# Options can be chained:
keyboard.resize(false).one_time.selective(true)

# Convert to hash for Telegram:
keyboard.to_h
```

Inline Keyboard

```ruby
inline = Telegem::Markup.inline do
  row callback("Option 1", "data1"),
      callback("Option 2", "data2")
  row url("Website", "https://example.com"),
      web_app("Open App", "https://app.example.com")
  row switch_inline("Search", "query"),
      switch_inline_current("Search Here", "")
end
```

Special Markups

```ruby
Telegem::Markup.remove(selective: false)        # Remove keyboard
Telegem::Markup.force_reply(selective: false)   # Force reply
```

---

🧙 Scenes (Wizard System)

Defining a Scene

```ruby
bot.scene :registration do
  step :ask_name do |ctx|
    ctx.reply "What's your name?"
  end
  
  step :save_name do |ctx|
    ctx.session[:name] = ctx.message.text
    ctx.reply "Thanks #{ctx.session[:name]}!"
    ctx.leave_scene
  end
  
  on_enter do |ctx|
    ctx.reply "Welcome to registration!"
  end
  
  on_leave do |ctx|
    ctx.reply "Registration complete!"
  end
end
```

Scene Methods

```ruby
scene.enter(ctx, step_name = :default)
scene.leave(ctx)
scene.current_step(ctx)
scene.reset(ctx)
```

---

🔌 Middleware

Using Middleware

```ruby
# Add built-in session middleware
bot.use Telegem::Session::Middleware.new

# Add custom middleware
bot.use do |ctx, next_middleware|
  puts "Before: #{ctx.message&.text}"
  next_middleware.call(ctx)
  puts "After"
end

# Add middleware class
class LoggingMiddleware
  def call(ctx, next_middleware)
    # Your code here
    next_middleware.call(ctx)
  end
end
bot.use LoggingMiddleware.new
```

---

💾 Session Stores

Available Stores

```ruby
# Memory store (default)
Telegem::Session::MemoryStore.new

# Redis store
require 'telegem/session/redis_store'
Telegem::Session::RedisStore.new(redis_client)

# File store
require 'telegem/session/file_store'
Telegem::Session::FileStore.new("sessions.json")
```

Session Middleware

```ruby
bot.use Telegem::Session::Middleware.new(
  store: store_object,    # defaults to MemoryStore
  key_prefix: "telegem:"  # optional prefix for storage keys
)
```

---

🌐 Webhook Server

Creating a Server

```ruby
server = bot.webhook_server(
  port: 3000,                     # default: 3000
  endpoint: endpoint_object,      # Async::HTTP::Endpoint
  logger: logger_object          # custom logger
)

server.run                      # Start async server
server.stop                     # Stop server
server.running?                 # Check if running
server.webhook_url              # Get full webhook URL
```

---

⚡ Bot Methods

Handler Registration

```ruby
bot.command(name, **options) { |ctx| }    # /command handler
bot.hears(pattern, **options) { |ctx| }   # Text pattern handler
bot.on(type, filters = {}) { |ctx| }      # Generic handler

# Handler types:
# - :message
# - :callback_query
# - :inline_query
# - :chat_member
# - :poll
# - :pre_checkout_query
# - :shipping_query
```

Bot Control

```ruby
bot.start_polling(**options)    # Start polling updates
bot.webhook_server(**options)   # Create webhook server
bot.set_webhook(url, **options) # Set webhook URL
bot.delete_webhook              # Remove webhook
bot.get_webhook_info            # Get webhook status
bot.shutdown                    # Graceful shutdown
```

Error Handling

```ruby
# Global error handler
bot.error do |error, ctx|
  ctx.reply "Oops: #{error.message}"
end
```

Scene Management

```ruby
bot.scene(name, &block)         # Define a scene
bot.scenes                      # Hash of all scenes
```

---

📞 Telegram API Methods

All methods below are available via ctx.api.call(method, params) or bot.api.call(method, params).

Message Methods

· sendMessage, sendPhoto, sendAudio, sendDocument
· sendVideo, sendVoice, sendSticker, sendLocation
· sendContact, sendPoll, sendDice, sendChatAction
· sendMediaGroup, forwardMessage, copyMessage
· editMessageText, editMessageCaption, editMessageMedia
· editMessageReplyMarkup, deleteMessage, pinChatMessage
· unpinChatMessage

Chat Methods

· getChat, getChatAdministrators, getChatMember
· getChatMembersCount, banChatMember, unbanChatMember
· restrictChatMember, promoteChatMember, setChatPermissions
· exportChatInviteLink, createChatInviteLink, revokeChatInviteLink
· approveChatJoinRequest, declineChatJoinRequest, setChatPhoto
· deleteChatPhoto, setChatTitle, setChatDescription
· setChatAdministratorCustomTitle, leaveChat

Callback & Inline Methods

· answerCallbackQuery, answerInlineQuery, answerWebAppQuery

Webhook Methods

· setWebhook, deleteWebhook, getWebhookInfo

Update Methods

· getUpdates

User & Bot Methods

· getMe, logOut, close

---

🎯 Common Options

Message Options

```ruby
{
  parse_mode: "HTML" | "Markdown" | "MarkdownV2",
  disable_web_page_preview: true,
  disable_notification: true,
  protect_content: true,
  reply_to_message_id: 123,
  allow_sending_without_reply: true,
  reply_markup: keyboard_object
}
```

Media Options

```ruby
{
  caption: "Description",
  parse_mode: "HTML",
  duration: 60,
  width: 1920,
  height: 1080,
  thumb: input_file,
  supports_streaming: true
}
```

Chat Member Options

```ruby
{
  until_date: Time.now + 3600,  # Unix timestamp
  revoke_messages: true
}
```

---

❗ Error Types

```ruby
Telegem::Error                     # Base error
Telegem::APIError                  # Telegram API errors
Telegem::NetworkError             # Network issues
Telegem::ValidationError          # Invalid parameters
```

---

Last updated for Telegem v0.1.0

```
---
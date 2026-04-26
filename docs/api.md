# API Reference

Complete reference for Telegem's API client and available methods.

## API Client

The `Telegem::API::Client` handles all communication with Telegram's Bot API.

### Initialization

```ruby
client = Telegem::API::Client.new(token, **options)
```

**Parameters:**
- `token` (String): Bot token
- `options` (Hash):
  - `logger` (Logger): Logger instance
  - `timeout` (Integer): Request timeout in seconds (default: 30)

### Methods

#### call(method, params = {})

Make a synchronous API call.

```ruby
result = client.call('sendMessage', {
  chat_id: 123,
  text: 'Hello'
})
```

#### call!(method, params = {}, &callback)

Make an asynchronous API call with callback.

```ruby
client.call!('sendMessage', { chat_id: 123, text: 'Hello' }) do |result, error|
  if error
    puts "Error: #{error.message}"
  else
    puts "Message sent: #{result['message_id']}"
  end
end
```

#### upload(method, params)

Upload files with multipart/form-data.

```ruby
client.upload('sendPhoto', {
  chat_id: 123,
  photo: File.open('image.jpg'),
  caption: 'Photo'
})
```

#### download(file_id, destination_path = nil)

Download files from Telegram.

```ruby
# Download to memory
content = client.download('file_id')

# Download to file
client.download('file_id', '/path/to/file.jpg')
```

#### get_updates(options = {})

Get updates (used internally by polling).

```ruby
updates = client.get_updates(
  offset: 123,
  limit: 100,
  timeout: 30,
  allowed_updates: ['message']
)
```

## Available API Methods

### Sending Messages

#### sendMessage

```ruby
bot.api.call('sendMessage', {
  chat_id: chat_id,
  text: 'Hello world',
  parse_mode: 'Markdown',  # 'Markdown' or 'HTML'
  disable_web_page_preview: true,
  reply_to_message_id: 123,
  reply_markup: keyboard_markup
})
```

#### sendPhoto

```ruby
bot.api.call('sendPhoto', {
  chat_id: chat_id,
  photo: 'file_id_or_url',
  caption: 'Photo caption',
  parse_mode: 'Markdown',
  reply_markup: keyboard
})
```

#### sendDocument

```ruby
bot.api.call('sendDocument', {
  chat_id: chat_id,
  document: file,
  caption: 'Document caption',
  parse_mode: 'Markdown'
})
```

#### sendAudio

```ruby
bot.api.call('sendAudio', {
  chat_id: chat_id,
  audio: file,
  caption: 'Audio caption',
  title: 'Song title',
  performer: 'Artist name',
  duration: 180
})
```

#### sendVideo

```ruby
bot.api.call('sendVideo', {
  chat_id: chat_id,
  video: file,
  caption: 'Video caption',
  duration: 60,
  width: 1920,
  height: 1080
})
```

#### sendVoice

```ruby
bot.api.call('sendVoice', {
  chat_id: chat_id,
  voice: file,  # OGG format required
  caption: 'Voice message',
  duration: 10
})
```

#### sendLocation

```ruby
bot.api.call('sendLocation', {
  chat_id: chat_id,
  latitude: 37.7749,
  longitude: -122.4194
})
```

#### sendContact

```ruby
bot.api.call('sendContact', {
  chat_id: chat_id,
  phone_number: '+1234567890',
  first_name: 'John',
  last_name: 'Doe'
})
```

#### sendPoll

```ruby
bot.api.call('sendPoll', {
  chat_id: chat_id,
  question: 'What\'s your favorite color?',
  options: ['Red', 'Blue', 'Green'],
  is_anonymous: true,
  allows_multiple_answers: false
})
```

### Editing Messages

#### editMessageText

```ruby
bot.api.call('editMessageText', {
  chat_id: chat_id,
  message_id: 123,
  text: 'Updated text',
  parse_mode: 'Markdown'
})
```

#### editMessageCaption

```ruby
bot.api.call('editMessageCaption', {
  chat_id: chat_id,
  message_id: 123,
  caption: 'New caption'
})
```

#### editMessageReplyMarkup

```ruby
bot.api.call('editMessageReplyMarkup', {
  chat_id: chat_id,
  message_id: 123,
  reply_markup: new_keyboard
})
```

### Deleting Messages

#### deleteMessage

```ruby
bot.api.call('deleteMessage', {
  chat_id: chat_id,
  message_id: 123
})
```

### Chat Management

#### getChat

```ruby
chat = bot.api.call('getChat', chat_id: chat_id)
```

#### getChatAdministrators

```ruby
admins = bot.api.call('getChatAdministrators', chat_id: chat_id)
```

#### getChatMembersCount

```ruby
count = bot.api.call('getChatMembersCount', chat_id: chat_id)
```

#### kickChatMember

```ruby
bot.api.call('kickChatMember', {
  chat_id: chat_id,
  user_id: user_id,
  until_date: future_timestamp,
  revoke_messages: true
})
```

#### banChatMember

```ruby
bot.api.call('banChatMember', {
  chat_id: chat_id,
  user_id: user_id,
  until_date: future_timestamp,
  revoke_messages: true
})
```

#### unbanChatMember

```ruby
bot.api.call('unbanChatMember', {
  chat_id: chat_id,
  user_id: user_id,
  only_if_banned: true
})
```

#### restrictChatMember

```ruby
bot.api.call('restrictChatMember', {
  chat_id: chat_id,
  user_id: user_id,
  permissions: {
    can_send_messages: false,
    can_send_media_messages: false
  },
  until_date: future_timestamp
})
```

#### promoteChatMember

```ruby
bot.api.call('promoteChatMember', {
  chat_id: chat_id,
  user_id: user_id,
  can_change_info: true,
  can_delete_messages: true,
  can_invite_users: true,
  can_restrict_members: true,
  can_pin_messages: true,
  can_promote_members: false
})
```

### Message Management

#### pinChatMessage

```ruby
bot.api.call('pinChatMessage', {
  chat_id: chat_id,
  message_id: 123,
  disable_notification: false
})
```

#### unpinChatMessage

```ruby
bot.api.call('unpinChatMessage', {
  chat_id: chat_id,
  message_id: 123
})
```

#### unpinAllChatMessages

```ruby
bot.api.call('unpinAllChatMessages', chat_id: chat_id)
```

#### forwardMessage

```ruby
bot.api.call('forwardMessage', {
  chat_id: destination_chat_id,
  from_chat_id: source_chat_id,
  message_id: 123,
  disable_notification: false
})
```

#### copyMessage

```ruby
bot.api.call('copyMessage', {
  chat_id: destination_chat_id,
  from_chat_id: source_chat_id,
  message_id: 123,
  caption: 'Copied message'
})
```

### Bot Commands

#### setMyCommands

```ruby
bot.api.call('setMyCommands', {
  commands: [
    { command: 'start', description: 'Start the bot' },
    { command: 'help', description: 'Get help' }
  ]
})
```

#### getMyCommands

```ruby
commands = bot.api.call('getMyCommands')
```

#### deleteMyCommands

```ruby
bot.api.call('deleteMyCommands')
```

### Webhook Management

#### setWebhook

```ruby
bot.api.call('setWebhook', {
  url: 'https://example.com/webhook',
  max_connections: 40,
  allowed_updates: ['message', 'callback_query'],
  secret_token: 'secret_token'
})
```

#### deleteWebhook

```ruby
bot.api.call('deleteWebhook')
```

#### getWebhookInfo

```ruby
info = bot.api.call('getWebhookInfo')
```

### File Operations

#### getFile

```ruby
file_info = bot.api.call('getFile', file_id: file_id)
file_path = file_info['file_path']
```

### Inline Queries

#### answerInlineQuery

```ruby
bot.api.call('answerInlineQuery', {
  inline_query_id: query_id,
  results: [result_objects],
  cache_time: 300,
  next_offset: '20'
})
```

### Callback Queries

#### answerCallbackQuery

```ruby
bot.api.call('answerCallbackQuery', {
  callback_query_id: callback_id,
  text: 'Button pressed!',
  show_alert: false,
  url: 'https://example.com',
  cache_time: 5
})
```

### Chat Actions

#### sendChatAction

```ruby
bot.api.call('sendChatAction', {
  chat_id: chat_id,
  action: 'typing'  # typing, upload_photo, upload_video, etc.
})
```

### Games

#### sendGame

```ruby
bot.api.call('sendGame', {
  chat_id: chat_id,
  game_short_name: 'my_game'
})
```

#### setGameScore

```ruby
bot.api.call('setGameScore', {
  user_id: user_id,
  score: 100,
  chat_id: chat_id,
  message_id: 123
})
```

### Payments

#### sendInvoice

```ruby
bot.api.call('sendInvoice', {
  chat_id: chat_id,
  title: 'Product',
  description: 'Description',
  payload: 'order_id',
  provider_token: 'payment_token',
  currency: 'USD',
  prices: [{ label: 'Price', amount: 1000 }]
})
```

#### answerShippingQuery

```ruby
bot.api.call('answerShippingQuery', {
  shipping_query_id: query_id,
  ok: true,
  shipping_options: [shipping_option]
})
```

#### answerPreCheckoutQuery

```ruby
bot.api.call('answerPreCheckoutQuery', {
  pre_checkout_query_id: query_id,
  ok: true
})
```

### Stickers

#### sendSticker

```ruby
bot.api.call('sendSticker', {
  chat_id: chat_id,
  sticker: sticker_file_id
})
```

#### getStickerSet

```ruby
sticker_set = bot.api.call('getStickerSet', name: 'sticker_set_name')
```

### Profile Management

#### setMyProfilePhoto

```ruby
bot.api.call('setMyProfilePhoto', {
  photo: photo_file
})
```

#### removeMyProfilePhoto

```ruby
bot.api.call('removeMyProfilePhoto')
```

### Business Features

#### sendBusinessMessage

```ruby
bot.api.call('sendBusinessMessage', {
  business_connection_id: connection_id,
  chat_id: chat_id,
  text: 'Business message'
})
```

## Context Methods

Convenience methods available on the context object.

### Message Sending

```ruby
ctx.reply(text, **options)
ctx.photo(file, **options)
ctx.document(file, **options)
ctx.audio(file, **options)
ctx.video(file, **options)
ctx.voice(file, **options)
ctx.sticker(file_id, **options)
ctx.location(lat, lng, **options)
ctx.contact(phone, first_name, **options)
```

### Message Editing

```ruby
ctx.edit_message_text(text, **options)
ctx.edit_message_caption(caption, **options)
ctx.edit_message_reply_markup(keyboard, **options)
ctx.delete_message(message_id)
```

### Chat Management

```ruby
ctx.kick_chat_member(user_id, **options)
ctx.ban_chat_member(user_id, **options)
ctx.unban_chat_member(user_id, **options)
ctx.restrict_chat_member(user_id, **options)
ctx.promote_chat_member(user_id, **options)
```

### Utilities

```ruby
ctx.answer_callback_query(**options)
ctx.answer_inline_query(results, **options)
ctx.send_chat_action(action, **options)
ctx.download_file(file_id, path)
```

## Error Handling

API calls raise `Telegem::API::APIError` on failure.

```ruby
begin
  result = bot.api.call('sendMessage', params)
rescue Telegem::API::APIError => e
  puts "API Error: #{e.message}"
  puts "Error code: #{e.code}" if e.code
end
```

### Common Error Codes

- `400` - Bad Request (invalid parameters)
- `401` - Unauthorized (invalid token)
- `403` - Forbidden (bot blocked by user)
- `404` - Not Found (chat/user not found)
- `429` - Too Many Requests (rate limited)

## Rate Limits

Telegram imposes rate limits on bot API calls:

- 30 messages per second for broadcasting
- 20 callback query answers per second
- 60 API calls per minute for other methods

Implement rate limiting middleware for high-traffic bots.

## File Upload Limits

- Photos: 10 MB
- Documents: 50 MB
- Videos: 50 MB (upload), 20 MB (via URL)
- Other files: 50 MB

## Best Practices

1. **Use appropriate timeouts** for your use case
2. **Handle API errors gracefully** with retries
3. **Implement rate limiting** to avoid hitting limits
4. **Validate parameters** before API calls
5. **Use webhooks** for production deployments
6. **Log API calls** for debugging
7. **Cache file IDs** to avoid re-uploading

The Telegram Bot API is extensive. Refer to the [official documentation](https://core.telegram.org/bots/api) for complete method reference.</content>
<parameter name="filePath">/home/slick/telegem/docs/api.md
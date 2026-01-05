bot1.md - Telegem Response Patterns

How Telegem Returns API Responses

All ctx methods return HTTPX::Response objects, not JSON hashes.

Pattern 1: Fire-and-Forget

```ruby
ctx.reply("Hello!")
ctx.photo("image.jpg")
```

Pattern 2: Get Message ID

```ruby
response = ctx.reply("Sending...")

if response && response.status == 200
  data = response.json
  if data && data['ok']
    message_id = data['result']['message_id']
    ctx.session[:msg_id] = message_id
  end
end
```

Pattern 3: Check for Errors

```ruby
response = ctx.reply("Testing...")

if response && response.status != 200
  error = response.json rescue nil
  error_msg = error['description'] if error
  ctx.reply("Failed: #{error_msg}")
end
```

Pattern 4: Edit Messages

```ruby
edit_response = ctx.edit_message_text(
  "Updated!", 
  message_id: ctx.session[:msg_id]
)

if edit_response && edit_response.status == 200
  ctx.reply("Edit succeeded!")
end
```

Pattern 5: Send Media

```ruby
photo_response = ctx.photo(
  "https://example.com/image.jpg",
  caption: "My photo"
)

if photo_response && photo_response.status == 200
  ctx.reply("Photo sent!")
end
```

Pattern 6: Handle Callbacks

```ruby
bot.on(:callback_query) do |ctx|
  ctx.answer_callback_query(text: "Clicked: #{ctx.data}")

  if ctx.data == 'test'
    ctx.edit_message_text("Updated after click!")
  end
end
```

Pattern 7: Error Wrapping

```ruby
begin
  response = ctx.reply(some_text)
  # Process response
rescue => e
  ctx.reply("Error: #{e.message}")
end
```

Complete bot1.rb Explained

Setup

```ruby
require 'telegem'
require 'dotenv/load'
bot = Telegem.new(ENV['BOT_TOKEN'])
```

/start Command

Sends welcome, stores message ID in session.

/help Command

Simple reply with command list.

/edit Command

Edits the stored message, checks edit response.

/photo Command

Sends photo, confirms delivery.

/error Command

Demonstrates error handling.

Callback Handler

Answers inline button clicks.

Startup Logic

```ruby
if ENV['RACK_ENV'] == 'production'
  # Webhook mode
  server = bot.webhook(port: ENV['PORT'] || 3000)
  server.run
  server.set_webhook
else
  # Polling mode (development)
  bot.start_polling(timeout: 30, limit: 100)
end
```

Key Takeaways

1. Always check response.status (200 = success)
2. Call .json to get data from response
3. Check data['ok'] before using result
4. Store message_id for later editing
5. Wrap in begin/rescue for network issues

This pattern ensures your bot handles all API scenarios correctly.
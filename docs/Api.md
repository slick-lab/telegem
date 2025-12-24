# Telegem API Reference (v2.0.0)

![Gem Version](https://img.shields.io/gem/v/telegem?color=blue)
![Ruby](https://img.shields.io/badge/Ruby-%3E%3D%203.0-red)
![License](https://img.shields.io/badge/license-MIT-green)
![Telegram Bot API](https://img.shields.io/badge/Telegram%20Bot%20API-7.0-lightblue)

Modern Telegram Bot Framework for Ruby. This guide details the core methods provided by the Telegem library, your modern toolkit for building Telegram bots with Ruby. Built on the official Telegram Bot API. For detailed parameter info, always check the official docs.

[![Join Official Channel](https://img.shields.io/badge/🔗-Join_Official_Channel-blue?style=flat&logo=telegram)](https://t.me/telegem_ruby)

---

## 1. 🤖 Core Bot Setup & Lifecycle

"First, solve the problem. Then, write the code." - John Johnson

These methods get your bot online and talking.

- **Telegem.new(token, **options)**
  - What it does: Creates your bot instance. This is your starting point.
  - Key Options: logger, timeout, max_threads, session_store.
  - Returns: A shiny new Telegem::Core::Bot object.

- **bot.start_polling(**options)**
  - What it does: Starts the classic "call-and-check" method for updates. Perfect for development.
  - Pro-tip: Don't use this if you have a webhook active (it's like trying to receive mail at two different houses).

- **bot.webhook(...)** or **Telegem.webhook(bot, ...)**
  - What it does: Sets up a production-grade server so Telegram can push updates directly to your bot. It's the recommended way for serious bots.
  - Telegem Superpowers:
    - Production-ready: Uses the Puma web server out of the box.
    - Cloud-Smart: Automatically figures out if you're on Render, Heroku, etc.
    - Secure: Validates incoming requests with a secret_token.
  - Helper: Call server.set_webhook() after server.run to tell Telegram where to find you.

- **bot.shutdown**
  - What it does: The polite way to tell your bot to stop. Closes connections and cleans up threads.

---

## 2. 📨 Update Handling & Events

"Programming is 10% writing code and 90% figuring out why it doesn't work." - Unknown Bot Developer

Tell your bot how to react to the world.

- **bot.on(type, filters = {}, &block)**
  - What it does: Your main tool for handling any event. Runs your code block when a matching update arrives.
  - Types: :message, :callback_query, :inline_query, :edited_message, etc.
  - Examples:
    ```ruby
    # Respond to text matching a regex
    bot.on(:message, text: /hello/i) { |ctx| ctx.reply("Hi there!") }
    # Handle a specific inline button press
    bot.on(:callback_query, data: "confirm") { |ctx| ctx.answer_callback_query(text: "Done!") }
    ```

- **bot.command(name, **options, &block)**
  - What it does: The easy way to handle slash commands like /start or /help.
  - Example:
    ```ruby
    bot.command("start") do |ctx|
      ctx.reply("Welcome to the future of Telegram bots!")
    end
    ```

- **bot.hears(pattern, **options, &block)**
  - What it does: A shortcut specifically for catching text messages with a regex pattern.

- **bot.use(middleware, *args, &block)**
  - What it does: Adds a middleware to the processing chain. Great for logging every request, checking user permissions, or adding timings.
  - Joke: Why did the developer go broke? He used up all his cache.

- **bot.error(&block)**
  - What it does: Sets up a global safety net to catch any errors that happen inside your handlers, so your bot doesn't just crash silently.

---

## 3. 🔄 The Context (ctx) Object - Your Swiss Army Knife

Inside every handler, you get a ctx object. It's your interface to do everything, from sending messages to managing chats. These methods return async HTTPX request objects.

"Talk is cheap. Show me the code." - Linus Torvalds (Probably while debugging a context method)

### A. Sending Messages & Content

- **ctx.reply(text, **options)** - Your bread and butter. Sends a text reply.
- **ctx.photo(photo, caption: nil, **options)** - Sends an image.
- **ctx.document(document, caption: nil, **options)** - Sends a file.
- **ctx.audio(audio, caption: nil, **options)** - Sends an audio file.
- **ctx.video(video, caption: nil, **options)** - Sends a video.
- **ctx.voice(voice, caption: nil, **options)** - Sends a voice message.
- **ctx.sticker(sticker, **options)** - Sends a sticker. Because communication is serious business.
- **ctx.location(latitude, longitude, **options)** - Shares a location.

### B. Managing Existing Messages

- **ctx.edit_message_text(text, **options)** - Changes the text of a message you sent.
- **ctx.delete_message(message_id = nil)** - Poof! Makes a message disappear. Defaults to the current message.
- **ctx.forward_message(from_chat_id, message_id, **options)** - Forwards a message from elsewhere.
- **ctx.copy_message(from_chat_id, message_id, **options)** - Copies a message (with forward info).
- **ctx.pin_message(message_id, **options)** - Pins a message in the chat.
- **ctx.unpin_message(**options)** - Unpins it.

### C. Chat Actions & Info

- **ctx.send_chat_action(action, **options)** - Shows a status like "typing..." or "uploading photo..." to users. Required: Be polite and use this for long operations!
- **ctx.get_chat(**options)** - Gets info about the current chat.
- **ctx.get_chat_administrators(**options)** - Lists the chat admins.
- **ctx.get_chat_members_count(**options)** - Counts chat members.

### D. Callback & Inline Queries

- **ctx.answer_callback_query(text: nil, show_alert: false, **options)** - Responds to a button press. Stops the loading animation on the button.
- **ctx.answer_inline_query(results, **options)** - Answers an inline query with a list of results.

### E. Chat Administration

- **ctx.kick_chat_member(user_id, **options)** - Removes a user from the chat.
- **ctx.ban_chat_member(user_id, **options)** - Bans a user.
- **ctx.unban_chat_member(user_id, **options)** - Unbans a user.

### F. Convenience Shortcuts

- **ctx.typing(**options)** - Shortcut for send_chat_action('typing').
- **ctx.uploading_photo(**options)** - Shortcut for send_chat_action('upload_photo').
- **ctx.with_typing(&block)** - A helper that shows "typing..." while your code block executes.
- **ctx.command?** - Returns true if the current message is a command.
- **ctx.command_args** - Returns the arguments provided after a command (e.g., for /search ruby, it returns "ruby").

---

## 4. ⌨️ Building Keyboards & Interactions

"The best interface is one that the user doesn't notice." - Let's help them not notice it's awesome.

Telegem provides a clean DSL for creating interactive keyboards.

- **Telegem.keyboard(&block)** - Creates a reply keyboard (appears where users type).
  ```ruby
  keyboard = Telegem.keyboard do
    row "Yes", "No"
    row "Maybe", "Cancel"
    resize true # Fits to screen width
    one_time true # Hides after one use
  end
  ctx.reply("Choose wisely:", reply_markup: keyboard)
```

· Telegem.inline(&block) - Creates an inline keyboard (appears inside the message).
  ```ruby
  inline_kb = Telegem.inline do
    row do
      callback_button "Approve", "approve_123"
      url_button "Read Docs", "https://gitlab.com/ruby-telegem/telegem"
    end
  end
  ctx.reply("What next?", reply_markup: inline_kb)
  ```

---

5. 🎭 Scene System & Session Management

"Good programmers write code that works. Great programmers write code that manages state." - Ancient Developer Proverb

Manage multi-step conversations (like a signup flow) easily.

· bot.scene(id, &block) - Defines a new scene with multiple steps.
· **ctx.enter_scene(scene_name, options) - Puts a user into a scene.
· ctx.leave_scene(options)** - Takes them out of it.
· ctx.session - A hash that automatically persists data for each user across different interactions. No setup required!

Scene Example:

```ruby
bot.scene("order") do
  step :ask_item do |ctx|
    ctx.reply("What would you like to order?")
    next_step :ask_quantity
  end

  step :ask_quantity do |ctx|
    ctx.state[:item] = ctx.message.text # Temp storage for this flow
    ctx.reply("How many?")
    next_step :confirm
  end

  step :confirm do |ctx|
    ctx.session[:last_order] = ctx.state[:item] # Save to persistent session
    ctx.reply("Order placed for #{ctx.state[:item]}! Thanks.")
    leave_scene
  end
end

# Start the scene with a command
bot.command("pizza") { |ctx| ctx.enter_scene("order") }
```

---

Quick Reference Table

Category Key Methods What it's for
Setup new, start_polling, webhook, shutdown Creating, running, and stopping your bot.
Events on, command, hears, use, error Defining how your bot reacts to messages and errors.
Actions ctx.reply, ctx.photo, ctx.edit_message_text Sending and managing messages and media.
Chat ctx.get_chat, ctx.ban_chat_member, ctx.pin_message Getting info and managing groups/channels.
UI Telegem.keyboard, Telegem.inline Creating interactive buttons for users.
Flow bot.scene, ctx.session, ctx.enter_scene Managing complex user conversations and data.
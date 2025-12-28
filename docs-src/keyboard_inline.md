
# Keyboards & Inline Keyboards Guide

Learn how to create interactive buttons for your Telegram bot.

## 📱 Two Types of Keyboards

### Reply Keyboard (Bottom of Chat)
**Position:** Always at the bottom of the chat screen
**Behavior:** User taps → Sends a text message to chat
**Best for:** Menus, forms, options that everyone should see
**Visibility:** All chat members see the keyboard

### Inline Keyboard (Under Messages)
**Position:** Attached to a specific message
**Behavior:** User taps → Triggers private callback (no chat message)
**Best for:** Polls, votes, games, interactive content
**Visibility:** Only people who see the message can tap

---

## ⌨️ Reply Keyboards

### Creating a Basic Keyboard
```ruby
# Simple 2x2 keyboard
keyboard = Telegem.keyboard do
  row "Yes", "No"           # First row with 2 buttons
  row "Maybe", "Cancel"     # Second row with 2 buttons
end

# Send with message
ctx.reply("Do you agree?", reply_markup: keyboard)
```

What happens:

1. User sees keyboard at bottom with 4 buttons
2. User taps "Yes"
3. Bot receives message: "Yes"
4. Everyone in chat sees "User: Yes"

Handling Keyboard Responses

```ruby
# When user taps "Yes" from keyboard
bot.hears("Yes") do |ctx|
  ctx.reply("Great! You agreed! ✅")
end

# When user taps "No"
bot.hears("No") do |ctx|
  ctx.reply("Oh, you disagreed ❌")
end
```

Keyboard Options

```ruby
keyboard = Telegem.keyboard do
  row "Option 1", "Option 2"
end.resize(false)           # Don't resize buttons (keep original size)
 .one_time(true)           # Hide keyboard after first use
 .selective(true)          # Show only to mentioned users

ctx.reply("Choose:", reply_markup: keyboard)
```

Special Button Types

```ruby
keyboard = Telegem.keyboard do
  request_contact("📞 Share Phone")    # Requests phone number
  request_location("📍 Share Location") # Requests GPS location
  request_poll("📊 Create Poll")       # Requests to create poll
end

ctx.reply("Share your info:", reply_markup: keyboard)
```

Removing Keyboards

```ruby
# Method 1: Using helper
ctx.reply("Keyboard removed", reply_markup: Telegem.remove)

# Method 2: After user makes choice
bot.hears("Done") do |ctx|
  ctx.reply("Finished!", reply_markup: { remove_keyboard: true })
end
```

Real Example: Pizza Order

```ruby
bot.command("order") do |ctx|
  # Step 1: Ask for size
  keyboard = Telegem.keyboard do
    row "Small 🍕", "Medium 🍕", "Large 🍕"
  end
  
  ctx.session[:step] = "size"
  ctx.reply("Choose pizza size:", reply_markup: keyboard)
end

# Handle size selection
bot.hears(/Small|Medium|Large/) do |ctx|
  if ctx.session[:step] == "size"
    ctx.session[:size] = ctx.message.text
    
    # Step 2: Ask for toppings
    keyboard = Telegem.keyboard do
      row "Cheese 🧀", "Pepperoni 🍖"
      row "Mushroom 🍄", "Veggie 🥦"
    end
    
    ctx.session[:step] = "topping"
    ctx.reply("Choose toppings:", reply_markup: keyboard)
  end
end
```

---

🔘 Inline Keyboards

Creating Basic Inline Buttons

```ruby
# Create inline keyboard
inline = Telegem.inline do
  row button "👍 Like", callback_data: "like"
  row button "👎 Dislike", callback_data: "dislike"
end

# Send message with buttons underneath
ctx.reply("Rate this message:", reply_markup: inline)
```

What happens:

1. Message appears with buttons under it
2. User taps "👍 Like"
3. NO message appears in chat
4. Bot receives private callback: data: "like"

Handling Inline Button Clicks

```ruby
# This handles ALL inline button clicks
bot.on(:callback_query) do |ctx|
  # ctx.data contains the callback_data from button
  
  case ctx.data
  when "like"
    # Show popup notification (disappears after 2 seconds)
    ctx.answer_callback_query(text: "Thanks for liking! ❤️")
    
    # Update the original message
    ctx.edit_message_text("✅ You liked this!")
    
  when "dislike"
    ctx.answer_callback_query(text: "Sorry you didn't like it 😢")
    ctx.edit_message_text("😞 You disliked this")
  end
end
```

Different Button Types

```ruby
inline = Telegem.inline do
  # Opens URL when clicked
  url "🌐 Visit Website", "https://example.com"
  
  # Triggers callback (most common)
  callback "✅ Select", "select_item_123"
  
  # Opens web app
  web_app "📱 Open App", "https://app.example.com"
  
  # Login with Telegram
  login "🔐 Login", "https://example.com/login"
  
  # Switch to inline mode
  switch_inline "🔍 Search", "cats"
end

ctx.reply("Choose action:", reply_markup: inline)
```

Interactive Quiz Example

```ruby
bot.command("quiz") do |ctx|
  inline = Telegem.inline do
    row button "Paris", callback_data: "answer_paris"
    row button "London", callback_data: "answer_london"
    row button "Berlin", callback_data: "answer_berlin"
  end
  
  ctx.reply("What is the capital of France?", reply_markup: inline)
end

bot.on(:callback_query) do |ctx|
  case ctx.data
  when "answer_paris"
    ctx.answer_callback_query(text: "✅ Correct! Paris is right!")
    ctx.edit_message_text("🎉 Correct! Paris is the capital of France")
    
  when "answer_london", "answer_berlin"
    ctx.answer_callback_query(text: "❌ Wrong! Try again", show_alert: true)
    # Keep same question for retry
  end
end
```

Pagination Example (Multiple Pages)

```ruby
ITEMS = ["Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape"]

def items_keyboard(page = 0)
  start = page * 3
  page_items = ITEMS[start, 3] || []
  
  Telegem.inline do
    # Current page items
    page_items.each do |item|
      row button item, callback_data: "select_#{item}"
    end
    
    # Navigation buttons
    row do
      if page > 0
        button "⬅️ Previous", callback_data: "page_#{page-1}"
      end
      button "📄 Page #{page+1}", callback_data: "current"
      if ITEMS.length > (page + 1) * 3
        button "Next ➡️", callback_data: "page_#{page+1}"
      end
    end
  end
end

bot.command("fruits") do |ctx|
  ctx.reply("Select a fruit:", reply_markup: items_keyboard)
end

bot.on(:callback_query) do |ctx|
  if ctx.data.start_with?("select_")
    fruit = ctx.data.split("_").last
    ctx.answer_callback_query(text: "Selected: #{fruit}")
    ctx.edit_message_text("You selected: #{fruit} 🍎")
    
  elsif ctx.data.start_with?("page_")
    page = ctx.data.split("_").last.to_i
    ctx.edit_message_reply_markup(items_keyboard(page))
    ctx.answer_callback_query  # Empty response (no popup)
  end
end
```

---

⚖️ When to Use Which?

Use Reply Keyboard When:

· Creating a main menu
· Collecting user information (name, age, etc.)
· Multi-step forms
· Simple yes/no questions
· You want everyone to see the choice

Use Inline Keyboard When:

· Creating polls or votes
· Interactive games
· Confirmation dialogs (delete? confirm?)
· Paginated lists
· You want to keep chat clean
· Private interactions

---

🔧 Best Practices

1. Button Text Length

```ruby
# ❌ Too long
button "Click here to confirm your selection and proceed to checkout"

# ✅ Concise and clear
button "Confirm Purchase"
button "Proceed to Checkout"
```

2. Logical Grouping

```ruby
# ✅ Group related actions
Telegem.keyboard do
  row "View Products", "View Cart"      # Shopping actions
  row "My Account", "Help"             # Account actions
  row "Cancel"                         # Cancel action
end
```

3. Callback Data Optimization

```ruby
# Store data efficiently in callback_data
# Format: "action:id:extra"
callback_data: "like:post_123:user_456"

# In handler
if ctx.data.start_with?("like:")
  action, post_id, user_id = ctx.data.split(":")
  # Process like
end
```

4. Error Handling

```ruby
bot.on(:callback_query) do |ctx|
  begin
    # Your button handling logic
  rescue => e
    ctx.answer_callback_query(
      text: "Something went wrong!",
      show_alert: true
    )
    ctx.logger.error("Button error: #{e.message}")
  end
end
```

---

🎮 Complete Game Example

```ruby
class NumberGame
  def self.start_game(ctx)
    inline = Telegem.inline do
      row button "1️⃣", callback_data: "guess_1"
      row button "2️⃣", callback_data: "guess_2"
      row button "3️⃣", callback_data: "guess_3"
      row button "4️⃣", callback_data: "guess_4"
      row button "5️⃣", callback_data: "guess_5"
    end
    
    ctx.session[:secret_number] = rand(1..5)
    ctx.reply("Guess the number (1-5):", reply_markup: inline)
  end
  
  def self.handle_guess(ctx)
    guess = ctx.data.split("_").last.to_i
    secret = ctx.session[:secret_number]
    
    if guess == secret
      ctx.answer_callback_query(text: "🎉 Correct! You won!")
      ctx.edit_message_text("✅ Correct! The number was #{secret}")
      
      # Play again button
      inline = Telegem.inline do
        row button "Play Again", callback_data: "play_again"
      end
      ctx.edit_message_reply_markup(inline)
      
    else
      ctx.answer_callback_query(text: "❌ Wrong! Try again")
      # Keep same buttons
    end
  end
end

# Register handlers
bot.command("game") { |ctx| NumberGame.start_game(ctx) }
bot.on(:callback_query) do |ctx|
  if ctx.data.start_with?("guess_")
    NumberGame.handle_guess(ctx)
  elsif ctx.data == "play_again"
    NumberGame.start_game(ctx)
  end
end
```

---

📚 Summary

Aspect Reply Keyboard Inline Keyboard
Position Bottom of chat Under message
Creates Message Yes No
Chat Visibility Everyone sees choice Private
Best For Menus, forms Polls, games
Response Method bot.hears() bot.on(:callback_query)
Clean Chat No (adds messages) Yes (no spam)

Remember:

· Reply keyboards = Public conversation
· Inline keyboards = Private interaction
· Choose based on whether you want choices visible to everyone

Start with simple keyboards, then add inline buttons for interactive features! 🚀

```
```
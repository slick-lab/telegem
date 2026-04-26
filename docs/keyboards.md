# Keyboard Markup

Telegem provides a clean DSL for creating inline and reply keyboards. Keyboards enable interactive buttons for better user experience.

## Reply Keyboards

Reply keyboards appear at the bottom of the chat and replace the system keyboard.

### Basic Reply Keyboard

```ruby
keyboard = Telegem.keyboard do
  row "Button 1", "Button 2"
  row "Button 3"
end

ctx.reply("Choose an option:", reply_markup: keyboard)
```

### Keyboard Options

```ruby
keyboard = Telegem.keyboard do
  row "Yes", "No"
end.resize.one_time.selective

ctx.reply("Confirm?", reply_markup: keyboard)
```

Available options:
- `resize` - Make keyboard smaller
- `one_time` - Hide keyboard after use
- `selective` - Show only to mentioned users

### Special Button Types

```ruby
keyboard = Telegem.keyboard do
  row "📍 Location", "📞 Contact"
  request_location "Share Location"
  request_contact "Share Contact"
  request_poll "Create Poll", poll_type: 'regular'
end

ctx.reply("What would you like to share?", reply_markup: keyboard)
```

## Inline Keyboards

Inline keyboards appear directly in messages and work with callback queries.

### Basic Inline Keyboard

```ruby
inline = Telegem.inline do
  row callback("Yes", "yes"), callback("No", "no")
  row url("Visit Site", "https://example.com")
end

ctx.reply("Do you agree?", reply_markup: inline)
```

### Button Types

#### Callback Buttons

```ruby
callback("Button Text", "callback_data")
```

- Text: Button label
- Data: String passed to callback handler (max 64 bytes)

#### URL Buttons

```ruby
url("Visit Website", "https://example.com")
```

Opens URL when pressed.

#### Login Buttons

```ruby
login("Login", "https://example.com/login", forward_text: "Login to site")
```

For web app authorization.

#### Web App Buttons

```ruby
web_app("Open App", "https://example.com/app")
```

Opens web app in Telegram interface.

#### Pay Buttons

```ruby
pay("Pay $10")
```

For payment integrations.

#### Game Buttons

```ruby
callback_game("Play Game", "game_short_name")
```

For HTML5 games.

### Advanced Inline Keyboard

```ruby
keyboard = Telegem.inline do
  # First row
  row callback("👍 Like", "like"), callback("👎 Dislike", "dislike")

  # Second row
  row url("📖 Read More", "https://example.com/article")

  # Third row
  row callback("🔔 Subscribe", "subscribe"), callback("🔕 Unsubscribe", "unsubscribe")

  # Fourth row
  row web_app("🎮 Play Game", "https://game.example.com")
end

ctx.reply("What do you think?", reply_markup: keyboard)
```

## Handling Button Presses

### Callback Query Handlers

```ruby
bot.callback_query do |ctx|
  data = ctx.data
  ctx.answer_callback_query("You pressed: #{data}")
end

# Specific data
bot.callback_query('like') do |ctx|
  ctx.answer_callback_query("Thanks for liking!")
  # Update message or database
end

# Pattern matching
bot.callback_query(/^action_/) do |ctx|
  action = ctx.data.split('_').last
  handle_action(ctx, action)
end
```

### Callback Query Methods

```ruby
ctx.answer_callback_query(text: "Processing...")
ctx.answer_callback_query(text: "Done!", show_alert: true)
ctx.answer_callback_query(url: "https://example.com")
ctx.answer_callback_query(cache_time: 30)
```

## Dynamic Keyboards

### Building from Data

```ruby
def create_menu_keyboard(options)
  Telegem.keyboard do
    options.each_slice(2) do |row_buttons|
      row(*row_buttons)
    end
  end.resize
end

options = ["Pizza", "Burger", "Salad", "Soup"]
keyboard = create_menu_keyboard(options)
ctx.reply("Choose food:", reply_markup: keyboard)
```

### Conditional Buttons

```ruby
def create_user_keyboard(ctx)
  Telegem.inline do
    row callback("Profile", "profile")

    if ctx.session[:admin]
      row callback("Admin Panel", "admin")
    end

    if ctx.session[:premium]
      row callback("Premium Features", "premium")
    end

    row callback("Settings", "settings")
  end
end

keyboard = create_user_keyboard(ctx)
ctx.reply("Menu:", reply_markup: keyboard)
```

## Keyboard Management

### Removing Keyboards

```ruby
# Remove reply keyboard
ctx.remove_keyboard
ctx.remove_keyboard("Keyboard removed!")

# Remove inline keyboard
ctx.edit_message_reply_markup(reply_markup: nil)
```

### Updating Keyboards

```ruby
# Edit inline keyboard
new_keyboard = Telegem.inline do
  row callback("Updated Button", "updated")
end

ctx.edit_message_reply_markup(reply_markup: new_keyboard)
```

### Force Reply

```ruby
# Force user to reply to message
ctx.reply("What's your name?", reply_markup: Telegem::Markup.force_reply)
```

## Advanced Patterns

### Pagination

```ruby
def create_pagination_keyboard(current_page, total_pages)
  Telegem.inline do
    row = []

    if current_page > 1
      row << callback("⬅️ Previous", "page:#{current_page - 1}")
    end

    row << callback("#{current_page}/#{total_pages}", "current")

    if current_page < total_pages
      row << callback("Next ➡️", "page:#{current_page + 1}")
    end

    row(*row)
  end
end

bot.callback_query(/^page:/) do |ctx|
  page = ctx.data.split(':').last.to_i
  keyboard = create_pagination_keyboard(page, 10)
  ctx.edit_message_reply_markup(reply_markup: keyboard)
end
```

### Multi-select Interface

```ruby
def create_selection_keyboard(selected_items, all_items)
  Telegem.inline do
    all_items.each do |item|
      status = selected_items.include?(item) ? "✅" : "⬜"
      row callback("#{status} #{item}", "toggle:#{item}")
    end

    row callback("Done", "done")
  end
end

bot.callback_query(/^toggle:/) do |ctx|
  item = ctx.data.split(':', 2).last
  selected = ctx.session[:selected] ||= []

  if selected.include?(item)
    selected.delete(item)
  else
    selected << item
  end

  keyboard = create_selection_keyboard(selected, ALL_ITEMS)
  ctx.edit_message_reply_markup(reply_markup: keyboard)
end
```

### Inline Search

```ruby
bot.inline_query do |ctx|
  query = ctx.query

  results = search_items(query).map do |item|
    Telegem::Types::InlineQueryResultArticle.new(
      id: item.id,
      title: item.title,
      description: item.description,
      input_message_content: {
        message_text: "Selected: #{item.title}"
      },
      reply_markup: Telegem.inline do
        callback "More Info", "info:#{item.id}"
      end
    )
  end

  ctx.answer_inline_query(results)
end
```

## Keyboard Best Practices

### Design Guidelines

1. **Keep it Simple**: 3-5 buttons per row, 2-3 rows max
2. **Clear Labels**: Use descriptive text and emojis
3. **Consistent Style**: Same button style for similar actions
4. **Progressive Disclosure**: Show more options as needed

### User Experience

```ruby
# Good: Clear, actionable buttons
keyboard = Telegem.inline do
  row callback("📅 Book Now", "book"), callback("ℹ️ More Info", "info")
  row callback("📞 Call Us", "call")
end

# Bad: Confusing, too many options
keyboard = Telegem.inline do
  row "Option A", "Option B", "Option C", "Option D", "Option E"
end
```

### Error Handling

```ruby
bot.callback_query do |ctx|
  begin
    handle_callback(ctx)
  rescue => e
    ctx.logger.error("Callback error: #{e.message}")
    ctx.answer_callback_query("Something went wrong", show_alert: true)
  end
end
```

### Performance Considerations

```ruby
# Cache keyboards for repeated use
KEYBOARDS = {
  main_menu: Telegem.inline do
    row callback("Home", "home"), callback("Settings", "settings")
  end
}

ctx.reply("Menu:", reply_markup: KEYBOARDS[:main_menu])
```

## Keyboard Types Reference

### Reply Keyboard Buttons

| Method | Description | Parameters |
|--------|-------------|------------|
| `text` | Regular text button | text, style, icon_custom_emoji_id |
| `request_contact` | Request phone number | text, style, icon_custom_emoji_id |
| `request_location` | Request location | text, style, icon_custom_emoji_id |
| `request_poll` | Request poll creation | text, poll_type, style, icon_custom_emoji_id |

### Inline Keyboard Buttons

| Method | Description | Parameters |
|--------|-------------|------------|
| `callback` | Callback query button | text, data, style, icon_custom_emoji_id |
| `url` | URL button | text, url, style, icon_custom_emoji_id |
| `login` | Login button | text, url, style, icon_custom_emoji_id, **options |
| `web_app` | Web app button | text, url, style, icon_custom_emoji_id |
| `pay` | Payment button | text, style, icon_custom_emoji_id |
| `switch_inline` | Switch to inline query | text, query, style, icon_custom_emoji_id |
| `switch_inline_current_chat` | Switch inline in current chat | text, query, style, icon_custom_emoji_id |
| `callback_game` | Game button | text, game_short_name, style, icon_custom_emoji_id |

## Testing Keyboards

```ruby
# Test keyboard creation
def test_keyboard_creation
  keyboard = Telegem.keyboard do
    row "Yes", "No"
  end

  assert keyboard.to_h.key?(:keyboard)
  assert_equal [["Yes", "No"]], keyboard.to_h[:keyboard]
end

# Test callback handling
def test_callback_handling
  # Simulate callback query
  simulate_callback_query(bot, "test_data")

  # Assert expected behavior
end
```

## Common Issues

### Callback Data Too Long

```ruby
# Bad: too much data
callback("Button", "very_long_data_that_exceeds_64_bytes_limit_and_will_cause_errors")

# Good: use IDs
callback("Button", "action:123")  # Reference by ID
```

### Keyboard Not Updating

```ruby
# Force update
ctx.edit_message_reply_markup(reply_markup: new_keyboard, message_id: ctx.message.message_id)
```

### Buttons Not Working

```ruby
# Check for typos in callback data
bot.callback_query('correct_data') do |ctx|
  # Handle callback
end
```

Keyboards are essential for creating interactive, user-friendly Telegram bots. Use them to guide users and collect input efficiently.</content>
<parameter name="filePath">/home/slick/telegem/docs/keyboards.md
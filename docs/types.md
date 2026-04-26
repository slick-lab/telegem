# Type System

Telegem provides Ruby classes for all Telegram API objects, offering type safety and convenient access methods.

## Base Type Class

All Telegram types inherit from `Telegem::Types::BaseType`.

### Features

- **Dynamic accessors**: Access any field as a method
- **Snake_case conversion**: API fields become Ruby methods
- **Type conversion**: Automatic conversion of nested objects
- **JSON serialization**: Convert to hash or JSON

### Usage

```ruby
# Access fields dynamically
user = Telegem::Types::User.new(api_response)
puts user.first_name
puts user.username

# Convert back to hash
user_hash = user.to_h

# Serialize to JSON
user_json = user.to_json
```

## Available Types

### User

Represents a Telegram user.

```ruby
user = Telegem::Types::User.new(data)

# Basic info
user.id              # Integer
user.first_name      # String
user.last_name       # String (optional)
user.username        # String (optional)
user.language_code   # String (optional)

# Status
user.is_bot          # Boolean
user.is_premium      # Boolean (optional)
user.added_to_attachment_menu  # Boolean (optional)

# Methods
user.full_name       # "First Last"
user.mention         # "@username" or "First"
```

### Chat

Represents a chat (private, group, supergroup, channel).

```ruby
chat = Telegem::Types::Chat.new(data)

# Basic info
chat.id              # Integer
chat.type            # "private", "group", "supergroup", "channel"
chat.title           # String (for groups/channels)
chat.username        # String (for public chats)
chat.first_name      # String (for private chats)
chat.last_name       # String (for private chats)

# Features
chat.description     # String (optional)
chat.invite_link     # String (optional)
chat.photo           # ChatPhoto object (optional)

# Permissions
chat.permissions     # ChatPermissions object

# Type checking
chat.private?        # chat.type == 'private'
chat.group?          # chat.type == 'group'
chat.supergroup?     # chat.type == 'supergroup'
chat.channel?        # chat.type == 'channel'
```

### Message

Represents a message in a chat.

```ruby
message = Telegem::Types::Message.new(data)

# Basic info
message.message_id   # Integer
message.date         # Time object
message.edit_date    # Time object (if edited)
message.text         # String (optional)
message.caption      # String (optional)

# Entities
message.entities     # Array of MessageEntity
message.caption_entities  # Array of MessageEntity

# Sender and chat
message.from         # User object
message.chat         # Chat object

# Reply info
message.reply_to_message  # Message object (optional)

# Media
message.photo        # Array of PhotoSize (optional)
message.document     # Document object (optional)
message.audio        # Audio object (optional)
message.video        # Video object (optional)
message.voice        # Voice object (optional)
message.sticker      # Sticker object (optional)

# Methods
message.command?     # Boolean: is command?
message.command_name # String: command name
message.command_args # String: command arguments
message.reply?       # Boolean: is reply?
message.has_media?   # Boolean: has media?
message.media_type   # Symbol: :photo, :document, etc.
```

### MessageEntity

Represents formatted text in messages.

```ruby
entity = Telegem::Types::MessageEntity.new(data)

entity.type          # "bold", "italic", "code", etc.
entity.offset        # Integer: start position
entity.length        # Integer: length
entity.url           # String (for links)
entity.user          # User object (for mentions)
entity.language      # String (for code blocks)
```

### Update

Represents an update from Telegram.

```ruby
update = Telegem::Types::Update.new(data)

update.update_id     # Integer

# Update types (only one will be present)
update.message       # Message object
update.edited_message # Message object
update.channel_post  # Message object
update.edited_channel_post  # Message object
update.inline_query  # InlineQuery object
update.chosen_inline_result  # ChosenInlineResult object
update.callback_query # CallbackQuery object
update.shipping_query # ShippingQuery object
update.pre_checkout_query  # PreCheckoutQuery object
update.poll          # Poll object
update.poll_answer   # PollAnswer object

# Type detection
update.type          # :message, :callback_query, etc.
update.from          # User object (sender)
```

### CallbackQuery

Represents a callback query from inline keyboard.

```ruby
query = Telegem::Types::CallbackQuery.new(data)

query.id             # String
query.from           # User object
query.message        # Message object (optional)
query.inline_message_id  # String (optional)
query.chat_instance  # String
query.data           # String (callback data)

# Type checking
query.from_user?     # query.from.present?
query.message?       # query.message.present?
query.inline_message? # query.inline_message_id.present?
```

### InlineQuery

Represents an inline query.

```ruby
query = Telegem::Types::InlineQuery.new(data)

query.id             # String
query.from           # User object
query.query          # String (search query)
query.offset         # String (pagination offset)
query.chat_type      # String (optional)
query.location       # Location object (optional)
```

### Poll

Represents a poll.

```ruby
poll = Telegem::Types::Poll.new(data)

poll.id              # String
poll.question        # String
poll.options         # Array of PollOption
poll.total_voter_count  # Integer
poll.is_closed       # Boolean
poll.is_anonymous    # Boolean
poll.allows_multiple_answers  # Boolean
poll.correct_option_id  # Integer (optional)
poll.explanation     # String (optional)
poll.explanation_entities  # Array of MessageEntity (optional)
```

### ChatMember

Represents a chat member.

```ruby
member = Telegem::Types::ChatMember.new(data)

member.user          # User object
member.status        # "creator", "administrator", "member", "restricted", "left", "kicked"

# Status-specific fields
member.custom_title  # String (for admins)
member.is_anonymous  # Boolean (for admins)
member.can_be_edited # Boolean (for admins)
member.can_manage_chat  # Boolean (for admins)
member.can_delete_messages  # Boolean (for admins)
member.can_manage_video_chats  # Boolean (for admins)
member.can_restrict_members  # Boolean (for admins)
member.can_promote_members  # Boolean (for admins)
member.can_change_info  # Boolean (for admins)
member.can_invite_users  # Boolean (for admins)
member.can_post_messages  # Boolean (for admins)
member.can_edit_messages  # Boolean (for admins)
member.can_pin_messages  # Boolean (for admins)
member.can_manage_topics  # Boolean (for admins)

# Restrictions (for restricted users)
member.is_member     # Boolean
member.can_send_messages  # Boolean
member.can_send_media_messages  # Boolean
member.can_send_polls  # Boolean
member.can_send_other_messages  # Boolean
member.can_add_web_page_previews  # Boolean
member.can_change_info  # Boolean
member.can_invite_users  # Boolean
member.can_pin_messages  # Boolean
member.can_manage_topics  # Boolean
member.until_date    # Time (restriction end)
```

## Media Types

### PhotoSize

```ruby
photo = Telegem::Types::PhotoSize.new(data)

photo.file_id        # String
photo.file_unique_id # String
photo.width          # Integer
photo.height         # Integer
photo.file_size      # Integer (optional)
```

### Document

```ruby
doc = Telegem::Types::Document.new(data)

doc.file_id          # String
doc.file_unique_id   # String
doc.file_name        # String (optional)
doc.mime_type        # String (optional)
doc.file_size        # Integer (optional)
doc.thumbnail        # PhotoSize (optional)
```

### Audio

```ruby
audio = Telegem::Types::Audio.new(data)

audio.file_id        # String
audio.file_unique_id # String
audio.duration       # Integer
audio.performer      # String (optional)
audio.title          # String (optional)
audio.file_name      # String (optional)
audio.mime_type      # String (optional)
audio.file_size      # Integer (optional)
audio.thumbnail      # PhotoSize (optional)
```

### Video

```ruby
video = Telegem::Types::Video.new(data)

video.file_id        # String
video.file_unique_id # String
video.width          # Integer
video.height         # Integer
video.duration       # Integer
video.file_name      # String (optional)
video.mime_type      # String (optional)
video.file_size      # Integer (optional)
video.thumbnail      # PhotoSize (optional)
```

### Voice

```ruby
voice = Telegem::Types::Voice.new(data)

voice.file_id        # String
voice.file_unique_id # String
voice.duration       # Integer
voice.mime_type      # String (optional)
voice.file_size      # Integer (optional)
```

### Animation

```ruby
anim = Telegem::Types::Animation.new(data)

anim.file_id         # String
anim.file_unique_id  # String
anim.width           # Integer
anim.height          # Integer
anim.duration        # Integer
anim.file_name       # String (optional)
anim.mime_type       # String (optional)
anim.file_size       # Integer (optional)
anim.thumbnail       # PhotoSize (optional)
```

### Sticker

```ruby
sticker = Telegem::Types::Sticker.new(data)

sticker.file_id      # String
sticker.file_unique_id # String
sticker.type         # "regular", "mask", "custom_emoji"
sticker.width        # Integer
sticker.height       # Integer
sticker.is_animated  # Boolean
sticker.is_video     # Boolean
sticker.emoji        # String (optional)
sticker.set_name     # String (optional)
sticker.premium_animation  # File (optional)
sticker.mask_position  # MaskPosition (optional)
sticker.custom_emoji_id  # String (optional)
sticker.needs_repainting  # Boolean (optional)
sticker.file_size    # Integer (optional)
```

## Utility Types

### Contact

```ruby
contact = Telegem::Types::Contact.new(data)

contact.phone_number # String
contact.first_name   # String
contact.last_name    # String (optional)
contact.user_id      # Integer (optional)
contact.vcard        # String (optional)
```

### Location

```ruby
location = Telegem::Types::Location.new(data)

location.latitude    # Float
location.longitude   # Float
location.horizontal_accuracy  # Float (optional)
location.live_period # Integer (optional)
location.heading     # Integer (optional)
location.proximity_alert_radius  # Integer (optional)
```

### Venue

```ruby
venue = Telegem::Types::Venue.new(data)

venue.location      # Location object
venue.title         # String
venue.address       # String
venue.foursquare_id # String (optional)
venue.foursquare_type  # String (optional)
venue.google_place_id  # String (optional)
venue.google_place_type  # String (optional)
```

### WebAppData

```ruby
web_app = Telegem::Types::WebAppData.new(data)

web_app.data        # String
web_app.button_text # String
```

## Inline Query Result Types

### InlineQueryResultArticle

```ruby
article = Telegem::Types::InlineQueryResultArticle.new(data)

article.id           # String
article.title        # String
article.input_message_content  # InputMessageContent
article.reply_markup # InlineKeyboardMarkup (optional)
article.url          # String (optional)
article.hide_url     # Boolean (optional)
article.description  # String (optional)
article.thumbnail_url  # String (optional)
article.thumbnail_width  # Integer (optional)
article.thumbnail_height  # Integer (optional)
```

### InlineQueryResultPhoto

```ruby
photo = Telegem::Types::InlineQueryResultPhoto.new(data)

photo.id             # String
photo.photo_url      # String
photo.thumbnail_url  # String
photo.photo_width    # Integer (optional)
photo.photo_height   # Integer (optional)
photo.title          # String (optional)
photo.description    # String (optional)
photo.caption        # String (optional)
photo.parse_mode     # String (optional)
photo.caption_entities  # Array of MessageEntity (optional)
photo.reply_markup   # InlineKeyboardMarkup (optional)
photo.input_message_content  # InputMessageContent (optional)
```

## Type Conversion

Types automatically convert nested objects:

```ruby
# Message with user and chat
message = Telegem::Types::Message.new(data)
message.from         # Automatically a User object
message.chat         # Automatically a Chat object
message.entities     # Array of MessageEntity objects
```

## Custom Types

Extend existing types or create new ones:

```ruby
class CustomUser < Telegem::Types::User
  def display_name
    username || full_name
  end

  def admin?
    # Custom logic
  end
end

# Use in conversions
Telegem::Types::Message.class_eval do
  def from
    CustomUser.new(@_raw_data['from']) if @_raw_data['from']
  end
end
```

## Error Handling

Type access may raise errors for missing fields:

```ruby
begin
  username = user.username
rescue NoMethodError
  # Field not present or nil
end

# Safe access
username = user.respond_to?(:username) ? user.username : nil
```

## Serialization

Convert types to various formats:

```ruby
user = Telegem::Types::User.new(data)

# To hash
user.to_h

# To JSON
user.to_json

# Pretty print
puts user.inspect
```

## Best Practices

1. **Use type checking** before accessing optional fields
2. **Handle nil values** gracefully
3. **Leverage helper methods** on types
4. **Extend types** for custom logic
5. **Use inspect** for debugging
6. **Convert to hash/JSON** for storage

The type system provides a Ruby-friendly interface to Telegram's API objects, making bot development more intuitive and type-safe.</content>
<parameter name="filePath">/home/slick/telegem/docs/types.md
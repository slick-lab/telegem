# Core Concepts

Understanding Telegem's architecture and key concepts will help you build better bots.

## Architecture Overview

Telegem follows a middleware-based architecture inspired by Express.js and Telegraf.js:

```
Update Received → Middleware Chain → Handler Matching → Response
```

## Key Components

### 1. Bot

The main bot instance that manages:

- Telegram API communication
- Handler registration
- Middleware pipeline
- Scene management
- Session storage

### 2. Context (ctx)

The context object passed to all handlers containing:

- Current update data
- Bot instance
- User/chat information
- Session data
- Response methods

### 3. Handlers

Functions that process specific types of updates:

- Commands (`/start`, `/help`)
- Text patterns
- Callback queries
- Inline queries
- Media messages

### 4. Middleware

Functions that process updates before handlers:

- Authentication
- Logging
- Rate limiting
- Session loading

### 5. Scenes

Multi-step conversation flows for complex interactions.

## Update Processing Flow

1. **Update Received**: Telegram sends an update via webhook or polling
2. **Middleware Execution**: Each middleware processes the update in order
3. **Handler Matching**: Bot finds matching handlers for the update type
4. **Handler Execution**: Matching handlers are called with the context
5. **Response**: Handlers send responses back to Telegram

## Async Architecture

Telegem uses Ruby's `async` gem for true asynchronous I/O:

- Non-blocking HTTP requests
- Concurrent update processing
- Efficient resource usage
- No thread blocking

## Type System

Telegem provides Ruby classes for all Telegram API objects:

- `User` - Telegram user information
- `Chat` - Chat/channel/group data
- `Message` - Message content and metadata
- `Update` - Telegram update wrapper

These classes provide:

- Type-safe access to properties
- Automatic data conversion
- Helper methods
- Snake_case attribute access

## Session Management

Sessions persist data between updates:

- User-specific storage
- Multiple backends (memory, Redis, custom)
- Automatic loading/saving
- TTL support

## Error Handling

Comprehensive error handling at multiple levels:

- Network errors
- API errors
- Handler exceptions
- Timeout handling
- Graceful degradation

## Threading Model

Telegem is single-threaded by default but async:

- One event loop handles all updates
- Concurrent I/O operations
- No shared mutable state issues
- Predictable execution order

## Memory Management

Efficient memory usage through:

- Lazy loading of update data
- Automatic cleanup of temporary files
- Session TTL and cleanup
- Minimal object retention

## Configuration

Flexible configuration options:

- Bot token and API settings
- Session store configuration
- Webhook server options
- Logging and debugging
- SSL/TLS settings

## Extensibility

Telegem is designed to be extended:

- Custom middleware
- Plugin system
- Custom session stores
- Type extensions
- Handler extensions

## Best Practices

### Handler Design

- Keep handlers small and focused
- Use middleware for cross-cutting concerns
- Handle errors gracefully
- Avoid blocking operations

### Session Usage

- Store minimal data
- Set appropriate TTL
- Clean up when done
- Handle session errors

### Performance

- Use webhooks in production
- Implement rate limiting
- Monitor memory usage
- Profile slow handlers

### Security

- Validate user input
- Use HTTPS for webhooks
- Store sensitive data securely
- Implement authentication when needed

## Common Patterns

### Command Processing

```ruby
bot.command('process') do |ctx|
  # Validate input
  # Process data
  # Send response
end
```

### Middleware Chain

```ruby
bot.use AuthenticationMiddleware
bot.use RateLimitMiddleware
bot.use LoggingMiddleware
```

### Scene Flow

```ruby
bot.scene :order do
  step :select_item
  step :confirm_order
  step :process_payment
end
```

### Error Handling

```ruby
bot.error do |error, ctx|
  logger.error("Handler error: #{error}")
  ctx.reply("Sorry, something went wrong!")
end
```

Understanding these concepts will help you build robust, scalable Telegram bots with Telegem.</content>
<parameter name="filePath">/home/slick/telegem/docs/core_concepts.md
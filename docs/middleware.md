# Middleware System

Middleware functions process updates before they reach handlers. They enable cross-cutting concerns like authentication, logging, and rate limiting.

## How Middleware Works

Middleware forms a pipeline that each update passes through:

```
Update → Middleware 1 → Middleware 2 → ... → Handlers → Response
```

Each middleware can:
- Modify the context
- Skip to the next middleware
- Stop processing
- Handle errors

## Basic Middleware

### Creating Middleware

```ruby
# Class-based middleware
class LoggingMiddleware
  def initialize(logger = nil)
    @logger = logger || Logger.new(STDOUT)
  end

  def call(ctx, next_middleware)
    @logger.info("Update from #{ctx.from&.id}")
    next_middleware.call(ctx)
  end
end

# Use it
bot.use LoggingMiddleware.new
```

### Inline Middleware

```ruby
bot.use do |ctx, next_middleware|
  puts "Processing update #{ctx.update_id}"
  next_middleware.call(ctx)
end
```

### Middleware with Arguments

```ruby
class RateLimitMiddleware
  def initialize(limit_per_minute: 10)
    @limit = limit_per_minute
    @requests = {}
  end

  def call(ctx, next_middleware)
    user_id = ctx.from&.id
    return next_middleware.call(ctx) unless user_id

    now = Time.now.to_i
    window_start = now - 60

    @requests[user_id] ||= []
    @requests[user_id].select! { |time| time > window_start }

    if @requests[user_id].size >= @limit
      ctx.reply("Rate limit exceeded")
      return
    end

    @requests[user_id] << now
    next_middleware.call(ctx)
  end
end

bot.use RateLimitMiddleware.new(limit_per_minute: 5)
```

## Built-in Middleware

Telegem automatically includes some middleware:

### Session Middleware

Loads and saves user sessions automatically.

```ruby
# Automatically included
# Uses bot's session_store
```

### Scene Middleware

Handles scene-based conversations.

```ruby
# Automatically included
# Processes scene steps
```

## Common Middleware Patterns

### Authentication

```ruby
class AuthMiddleware
  def initialize(allowed_users: [])
    @allowed_users = allowed_users
  end

  def call(ctx, next_middleware)
    user_id = ctx.from&.id

    unless @allowed_users.include?(user_id)
      ctx.reply("Access denied")
      return
    end

    next_middleware.call(ctx)
  end
end

bot.use AuthMiddleware.new(allowed_users: [123456, 789012])
```

### Logging

```ruby
class DetailedLoggingMiddleware
  def call(ctx, next_middleware)
    start_time = Time.now

    log_request(ctx)

    begin
      next_middleware.call(ctx)
      log_success(ctx, Time.now - start_time)
    rescue => e
      log_error(ctx, e, Time.now - start_time)
      raise
    end
  end

  private

  def log_request(ctx)
    puts "[#{Time.now}] #{ctx.update_type} from #{ctx.from&.id}"
  end

  def log_success(ctx, duration)
    puts "[#{Time.now}] SUCCESS #{duration.round(3)}s"
  end

  def log_error(ctx, error, duration)
    puts "[#{Time.now}] ERROR #{error.class}: #{error.message} (#{duration.round(3)}s)"
  end
end
```

### Input Validation

```ruby
class ValidationMiddleware
  def call(ctx, next_middleware)
    if ctx.message&.text
      # Sanitize input
      ctx.message.instance_variable_set(:@text, sanitize_text(ctx.message.text))
    end

    next_middleware.call(ctx)
  end

  private

  def sanitize_text(text)
    # Remove potentially harmful content
    text.gsub(/[<>'"&]/, '').strip
  end
end
```

### Language Detection

```ruby
class LanguageMiddleware
  def call(ctx, next_middleware)
    if ctx.from&.language_code
      ctx.state[:language] = ctx.from.language_code
      ctx.session[:language] ||= ctx.from.language_code
    end

    next_middleware.call(ctx)
  end
end
```

### Bot Command Filtering

```ruby
class BotCommandMiddleware
  def call(ctx, next_middleware)
    if ctx.message&.text&.include?('@')
      # Check if command is for this bot
      bot_username = ctx.bot.api.call('getMe')['username']
      unless ctx.message.text.include?("@#{bot_username}")
        return  # Skip this update
      end
    end

    next_middleware.call(ctx)
  end
end
```

## Advanced Middleware

### Conditional Middleware

```ruby
class ConditionalMiddleware
  def initialize(condition_proc, middleware)
    @condition = condition_proc
    @middleware = middleware
  end

  def call(ctx, next_middleware)
    if @condition.call(ctx)
      @middleware.call(ctx, next_middleware)
    else
      next_middleware.call(ctx)
    end
  end
end

# Use only in groups
group_only = ConditionalMiddleware.new(
  ->(ctx) { ctx.chat&.type == 'group' },
  GroupMiddleware.new
)
bot.use group_only
```

### Async Middleware

```ruby
class AsyncProcessingMiddleware
  def call(ctx, next_middleware)
    Async do
      # Do async work
      result = await some_async_operation(ctx)

      # Modify context
      ctx.state[:async_result] = result

      # Continue
      next_middleware.call(ctx)
    end
  end
end
```

### Middleware Chains

```ruby
class MiddlewareChain
  def initialize(*middlewares)
    @middlewares = middlewares
  end

  def call(ctx, final_handler)
    chain = build_chain(final_handler)
    chain.call(ctx)
  end

  private

  def build_chain(final_handler)
    @middlewares.reverse.inject(final_handler) do |next_middleware, middleware|
      ->(ctx) { middleware.call(ctx, next_middleware) }
    end
  end
end

# Usage
chain = MiddlewareChain.new(
  LoggingMiddleware.new,
  AuthMiddleware.new,
  RateLimitMiddleware.new
)

bot.use chain
```

## Middleware Order Matters

Order middleware from most general to most specific:

```ruby
bot.use LoggingMiddleware.new        # Log everything
bot.use RateLimitMiddleware.new      # Rate limit all requests
bot.use AuthMiddleware.new           # Authenticate users
bot.use LanguageMiddleware.new       # Set language preferences
# Handlers...
```

## Error Handling in Middleware

```ruby
class SafeMiddleware
  def call(ctx, next_middleware)
    begin
      next_middleware.call(ctx)
    rescue => e
      ctx.logger.error("Middleware error: #{e.message}")
      ctx.reply("Something went wrong") if ctx.chat
    end
  end
end

# Wrap all middleware in safety
bot.use SafeMiddleware.new
```

## Testing Middleware

```ruby
# Test middleware in isolation
def test_middleware(middleware_class, ctx)
  called = false

  middleware_class.new.call(ctx, ->(ctx) { called = true })

  assert called, "Next middleware should be called"
end

# Integration test
def test_middleware_chain(bot, update_data)
  update = Telegem::Types::Update.new(update_data)
  ctx = Telegem::Core::Context.new(update, bot)

  # Process through middleware
  bot.process_update(update)

  # Assert expected behavior
end
```

## Built-in Middleware Reference

### Session::Middleware

- Loads session data before handlers
- Saves session data after handlers
- Handles session store errors gracefully

### Scene::Middleware

- Intercepts updates for active scenes
- Routes to scene steps
- Handles scene timeouts

## Best Practices

### 1. Keep Middleware Focused

Each middleware should do one thing well.

```ruby
# Bad: one middleware doing everything
class MonolithicMiddleware
  def call(ctx, next_middleware)
    log_request(ctx)
    check_auth(ctx)
    validate_input(ctx)
    next_middleware.call(ctx)
  end
end

# Good: separate concerns
bot.use LoggingMiddleware.new
bot.use AuthMiddleware.new
bot.use ValidationMiddleware.new
```

### 2. Handle Errors Gracefully

```ruby
class RobustMiddleware
  def call(ctx, next_middleware)
    begin
      next_middleware.call(ctx)
    rescue => e
      handle_error(ctx, e)
      # Decide whether to continue or stop
    end
  end
end
```

### 3. Make Middleware Configurable

```ruby
class ConfigurableMiddleware
  def initialize(options = {})
    @options = default_options.merge(options)
  end

  def call(ctx, next_middleware)
    if @options[:enabled]
      # Do work
    end
    next_middleware.call(ctx)
  end
end
```

### 4. Use Appropriate Scoping

```ruby
# Global middleware (affects all updates)
bot.use GlobalLoggingMiddleware.new

# Conditional middleware
bot.use ConditionalMiddleware.new(
  ->(ctx) { ctx.chat&.group? },
  GroupOnlyMiddleware.new
)
```

### 5. Document Middleware Behavior

```ruby
class DocumentedMiddleware
  # This middleware:
  # - Validates user input
  # - Sanitizes text content
  # - Rejects messages over 1000 characters
  # - Logs validation failures

  def call(ctx, next_middleware)
    # Implementation
  end
end
```

### 6. Test Middleware Thoroughly

```ruby
describe ValidationMiddleware do
  it "rejects empty messages" do
    ctx = create_context(text: "")
    middleware.call(ctx, ->(_) { @called = true })
    expect(@called).to be false
  end

  it "allows valid messages" do
    ctx = create_context(text: "valid")
    middleware.call(ctx, ->(_) { @called = true })
    expect(@called).to be true
  end
end
```

## Common Middleware Examples

### User Tracking

```ruby
class UserTrackingMiddleware
  def call(ctx, next_middleware)
    if ctx.from
      ctx.session[:last_seen] = Time.now.to_i
      ctx.session[:message_count] ||= 0
      ctx.session[:message_count] += 1
    end

    next_middleware.call(ctx)
  end
end
```

### Feature Flags

```ruby
class FeatureFlagMiddleware
  def initialize(feature_name)
    @feature_name = feature_name
  end

  def call(ctx, next_middleware)
    if feature_enabled?(@feature_name, ctx.from&.id)
      next_middleware.call(ctx)
    else
      ctx.reply("Feature not available")
    end
  end
end
```

### Request Timing

```ruby
class TimingMiddleware
  def call(ctx, next_middleware)
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    next_middleware.call(ctx)
    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start

    ctx.logger.info("Request took #{duration.round(3)}s")
  end
end
```

### Content Filtering

```ruby
class ContentFilterMiddleware
  BANNED_WORDS = ['spam', 'inappropriate']

  def call(ctx, next_middleware)
    if ctx.message&.text
      if BANNED_WORDS.any? { |word| ctx.message.text.include?(word) }
        ctx.delete_message
        return
      end
    end

    next_middleware.call(ctx)
  end
end
```

Middleware is powerful for adding cross-cutting functionality to your bot. Use it to separate concerns and keep handlers focused on business logic.</content>
<parameter name="filePath">/home/slick/telegem/docs/middleware.md
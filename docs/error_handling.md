# Error Handling

Comprehensive error handling is crucial for robust Telegram bots. Telegem provides multiple layers of error handling with recovery strategies.

## Error Types

### API Errors

Telegram API errors from invalid requests or server issues.

```ruby
begin
  bot.api.call('sendMessage', invalid_params)
rescue Telegem::API::APIError => e
  puts "API Error: #{e.message}"
  puts "Error code: #{e.code}" if e.code
end
```

**Common API Error Codes:**
- `400` - Bad Request (invalid parameters)
- `401` - Unauthorized (invalid token)
- `403` - Forbidden (bot blocked/kicked)
- `404` - Not Found (chat/user not found)
- `429` - Too Many Requests (rate limited)

### Network Errors

Connection issues, timeouts, DNS failures.

```ruby
begin
  result = bot.api.call('sendMessage', params)
rescue Telegem::API::NetworkError => e
  puts "Network error: #{e.message}"
  # Retry logic
end
```

### Handler Errors

Exceptions in message handlers.

```ruby
bot.error do |error, ctx|
  ctx.logger.error("Handler error: #{error.message}")
  ctx.logger.error("User: #{ctx.from&.id}, Chat: #{ctx.chat&.id}")

  # Send user-friendly message
  ctx.reply("Sorry, something went wrong. Please try again.") if ctx.chat
end
```

## Global Error Handler

Catch all unhandled errors in handlers.

```ruby
bot.error do |error, ctx|
  case error
  when Telegem::API::APIError
    handle_api_error(error, ctx)
  when StandardError
    handle_generic_error(error, ctx)
  end
end

def handle_api_error(error, ctx)
  case error.code
  when 403
    ctx.reply("I don't have permission to do that.")
  when 429
    ctx.reply("Please wait a moment before trying again.")
  else
    ctx.reply("API error occurred.")
  end
end

def handle_generic_error(error, ctx)
  ctx.logger.error("Unexpected error: #{error.class}: #{error.message}")
  ctx.logger.error(error.backtrace.join("\n"))
  ctx.reply("An unexpected error occurred.")
end
```

## Handler-Level Error Handling

Handle errors within specific handlers.

```ruby
bot.command('process') do |ctx|
  begin
    data = process_user_input(ctx.text)
    result = perform_calculation(data)
    ctx.reply("Result: #{result}")
  rescue ArgumentError => e
    ctx.reply("Invalid input: #{e.message}")
  rescue ZeroDivisionError
    ctx.reply("Cannot divide by zero")
  rescue => e
    ctx.logger.error("Processing error: #{e.message}")
    ctx.reply("Processing failed. Please try again.")
  end
end
```

## Middleware Error Handling

Handle errors in middleware chain.

```ruby
class SafeMiddleware
  def call(ctx, next_middleware)
    begin
      next_middleware.call(ctx)
    rescue => e
      ctx.logger.error("Middleware error: #{e.message}")
      # Continue processing or re-raise
      raise
    end
  end
end

# Use safe wrapper
bot.use SafeMiddleware.new
bot.use ProblematicMiddleware.new
```

## Async Error Handling

Handle errors in async operations.

```ruby
bot.command('async_task') do |ctx|
  ctx.reply("Processing...")

  Async do
    begin
      result = perform_async_operation()
      ctx.reply("Success: #{result}")
    rescue => e
      ctx.logger.error("Async error: #{e.message}")
      ctx.reply("Operation failed")
    end
  end
end
```

## Network Resilience

Handle network issues with retries.

```ruby
class RetryMiddleware
  def initialize(max_retries: 3, backoff: 1)
    @max_retries = max_retries
    @backoff = backoff
  end

  def call(ctx, next_middleware)
    retries = 0

    begin
      next_middleware.call(ctx)
    rescue Telegem::API::NetworkError => e
      retries += 1
      if retries <= @max_retries
        sleep(@backoff * retries)
        retry
      else
        raise
      end
    end
  end
end

bot.use RetryMiddleware.new(max_retries: 3)
```

## Rate Limiting Errors

Handle Telegram's rate limits.

```ruby
class RateLimitHandler
  def call(ctx, next_middleware)
    begin
      next_middleware.call(ctx)
    rescue Telegem::API::APIError => e
      if e.code == 429
        # Rate limited
        retry_after = parse_retry_after(e.message)
        ctx.logger.warn("Rate limited, retry after #{retry_after}s")

        if retry_after && retry_after < 60
          sleep(retry_after)
          retry
        else
          ctx.reply("Service temporarily unavailable")
        end
      else
        raise
      end
    end
  end

  private

  def parse_retry_after(message)
    # Parse retry-after from error message
    match = message.match(/retry after (\d+)/)
    match ? match[1].to_i : nil
  end
end
```

## File Operation Errors

Handle file upload/download errors.

```ruby
bot.document do |ctx|
  begin
    file_id = ctx.message.document.file_id
    content = ctx.download_file(file_id)

    # Process content
    result = process_file(content)
    ctx.reply("File processed successfully")

  rescue => e
    ctx.logger.error("File processing error: #{e.message}")
    ctx.reply("Failed to process file. Please try again.")
  end
end
```

## Session Errors

Handle session storage failures.

```ruby
class SessionErrorHandler
  def call(ctx, next_middleware)
    begin
      next_middleware.call(ctx)
    rescue => e
      if e.message.include?('session')
        ctx.logger.error("Session error: #{e.message}")
        # Continue without session
        ctx.instance_variable_set(:@session, {})
      else
        raise
      end
    end

    next_middleware.call(ctx)
  end
end
```

## Validation Errors

Validate user input before processing.

```ruby
class ValidationError < StandardError; end

def validate_input(text)
  raise ValidationError, "Text is required" if text.nil? || text.empty?
  raise ValidationError, "Text too long" if text.length > 1000
  raise ValidationError, "Invalid characters" unless text.match?(/\A[\w\s]+\z/)
end

bot.command('validate') do |ctx|
  begin
    validate_input(ctx.text)
    ctx.reply("Input is valid")
  rescue ValidationError => e
    ctx.reply("Validation error: #{e.message}")
  end
end
```

## Graceful Degradation

Continue operating when some features fail.

```ruby
bot.command('complex') do |ctx|
  result = {}

  # Try optional features
  begin
    result[:feature1] = optional_feature1()
  rescue => e
    ctx.logger.warn("Feature 1 failed: #{e.message}")
  end

  begin
    result[:feature2] = optional_feature2()
  rescue => e
    ctx.logger.warn("Feature 2 failed: #{e.message}")
  end

  # Core functionality
  result[:core] = core_functionality()

  ctx.reply("Result: #{result}")
end
```

## Error Monitoring

Log and monitor errors for debugging.

```ruby
class ErrorMonitoringMiddleware
  def initialize(error_tracker)
    @error_tracker = error_tracker
  end

  def call(ctx, next_middleware)
    begin
      next_middleware.call(ctx)
    rescue => e
      # Log error with context
      error_data = {
        error: e.message,
        class: e.class.name,
        backtrace: e.backtrace.first(10),
        user_id: ctx.from&.id,
        chat_id: ctx.chat&.id,
        update_type: ctx.update_type,
        timestamp: Time.now.to_i
      }

      @error_tracker.report(error_data)

      # Re-raise to let other handlers deal with it
      raise
    end
  end
end
```

## User Communication

Provide helpful error messages to users.

```ruby
ERROR_MESSAGES = {
  'network' => "Connection problem. Please try again.",
  'timeout' => "Request timed out. Please try again.",
  'invalid_input' => "Please check your input and try again.",
  'permission_denied' => "I don't have permission to do that.",
  'not_found' => "The requested item was not found.",
  'rate_limited' => "Too many requests. Please wait a moment.",
  'server_error' => "Server error. Please try again later."
}

def user_friendly_error(error_type, ctx)
  message = ERROR_MESSAGES[error_type] || "An error occurred."
  ctx.reply(message)
end

bot.error do |error, ctx|
  error_type = classify_error(error)
  user_friendly_error(error_type, ctx)
end

def classify_error(error)
  case error
  when Telegem::API::NetworkError
    'network'
  when Timeout::Error
    'timeout'
  when Telegem::API::APIError
    case error.code
    when 403 then 'permission_denied'
    when 404 then 'not_found'
    when 429 then 'rate_limited'
    else 'server_error'
    end
  else
    'server_error'
  end
end
```

## Testing Error Scenarios

```ruby
# Test error handlers
def test_error_handling
  # Simulate API error
  allow(bot.api).to receive(:call).and_raise(Telegem::API::APIError.new("Test error"))

  # Trigger handler
  simulate_message(bot, '/test')

  # Assert error handling
  expect(last_response).to include("error occurred")
end

# Test network resilience
def test_network_retry
  call_count = 0
  allow(bot.api).to receive(:call) do
    call_count += 1
    raise Telegem::API::NetworkError.new("Connection failed") if call_count < 3
    { ok: true }
  end

  simulate_message(bot, '/retry_test')

  expect(call_count).to eq(3)
end
```

## Best Practices

1. **Always implement global error handlers**
2. **Use specific error types for different scenarios**
3. **Provide user-friendly error messages**
4. **Log errors with sufficient context**
5. **Implement retry logic for transient errors**
6. **Use circuit breakers for external services**
7. **Monitor error rates and patterns**
8. **Test error scenarios thoroughly**
9. **Gracefully degrade when features fail**
10. **Validate input before processing**

Proper error handling ensures your bot remains stable and provides a good user experience even when things go wrong.</content>
<parameter name="filePath">/home/slick/telegem/docs/error_handling.md
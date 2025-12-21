📘 Telegem Usage Guide

For developers who know Ruby and want to build real, production-ready bots. This guide focuses on practical patterns, best practices, and the powerful features that make Telegem special.

---

🎯 Quick Navigation

• Scenes & Wizard Flows
• Middleware Patterns
• Session Management
• Error Handling Strategies
• Webhook Deployment
• Testing Your Bot
• Performance Tips

---

🧙 Scenes & Wizard Flows

Scenes handle multi-step conversations - perfect for forms, surveys, onboarding, or any back-and-forth interaction.

Why Scenes?

Imagine building a job application bot without scenes:

```ruby
# ❌ The messy way (without scenes)
bot.command('apply') do |ctx|
  ctx.reply "What's your name?"
  # Now what? How do we wait for response?
  # Where do we store their answer?
  # How do we know what step we're on?
end
```

With scenes, it becomes clean:

```ruby
# ✅ The clean way (with scenes)
bot.scene :job_application do
  step :ask_name do |ctx|
    ctx.reply "What's your full name?"
  end
  
  step :save_name do |ctx|
    ctx.session[:name] = ctx.message.text
    ctx.reply "Thanks #{ctx.session[:name]}! What's your email?"
  end
  
  step :save_email do |ctx|
    ctx.session[:email] = ctx.message.text
    ctx.reply "Great! One more question..."
    # Automatically goes to next step
  end
end
```

Scene Lifecycle

Every scene has a clear lifecycle:

```
┌─────────────────────┐
│    Scene Created    │
│   (bot.scene :id)   │
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│     on_enter        │  ← Runs once when scene starts
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│       step 1        │  ← First interaction
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│       step 2        │  ← Waits for user input
└──────────┬──────────┘
           │
    (more steps...)
           │
┌──────────▼──────────┐
│     on_leave        │  ← Runs when scene ends
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│    Scene Ended      │
│   (ctx.leave_scene) │
└─────────────────────┘
```

Practical Scene Example: Restaurant Booking

```ruby
bot.scene :restaurant_booking do
  on_enter do |ctx|
    ctx.session[:booking_id] = SecureRandom.hex(6)
    ctx.reply "Welcome to our booking system! 🍽️"
  end
  
  step :ask_date do |ctx|
    keyboard = Telegem::Markup.inline do
      row callback("Today", "date_today"),
          callback("Tomorrow", "date_tomorrow")
      row callback("Pick date...", "date_custom")
    end
    ctx.reply "When would you like to book?", reply_markup: keyboard
  end
  
  step :handle_date do |ctx|
    case ctx.data
    when "date_today"
      ctx.session[:date] = Date.today
    when "date_tomorrow"
      ctx.session[:date] = Date.today + 1
    when "date_custom"
      ctx.reply "Please send the date (YYYY-MM-DD):"
      return  # Stay in this step for custom input
    end
    
    ctx.reply "Great! How many people?"
  end
  
  step :save_people do |ctx|
    ctx.session[:people] = ctx.message.text.to_i
    
    # Show summary
    summary = <<~SUMMARY
      📋 Booking Summary:
      
      ID: #{ctx.session[:booking_id]}
      Date: #{ctx.session[:date]}
      People: #{ctx.session[:people]}
      
      Confirm? (yes/no)
    SUMMARY
    
    ctx.reply summary
  end
  
  step :confirm do |ctx|
    if ctx.message.text.downcase == 'yes'
      # Save to database here
      ctx.reply "✅ Booking confirmed! Your ID: #{ctx.session[:booking_id]}"
      ctx.leave_scene
    else
      ctx.reply "❌ Booking cancelled."
      ctx.leave_scene
    end
  end
  
  on_leave do |ctx|
    ctx.reply "Thank you for using our booking system!"
    # Clean up session if needed
    ctx.session.delete(:booking_id)
  end
end
```

Scene Best Practices

• Keep scenes focused - One scene per flow (booking, survey, game)
• Use session for state - Don't use global variables
• Handle cancellation - Always allow ctx.leave_scene
• Validate input - Check user responses make sense
• Clear session on exit - Avoid stale data

---

🔌 Middleware Patterns

Middleware runs on every update, making it perfect for cross-cutting concerns.

The Middleware Stack

```ruby
# Order matters! Top runs first
bot.use AuthenticationMiddleware.new
bot.use LoggingMiddleware.new
bot.use RateLimiter.new
bot.use SessionMiddleware.new
# Your command handlers run here
```

Common Middleware Examples

1. Authentication

```ruby
class AdminOnlyMiddleware
  ADMIN_IDS = [12345, 67890]
  
  def call(ctx, next_middleware)
    if ADMIN_IDS.include?(ctx.from.id)
      next_middleware.call(ctx)
    else
      ctx.reply "⛔ Admin access required"
    end
  end
end
```

2. Logging

```ruby
class RequestLogger
  def call(ctx, next_middleware)
    start_time = Time.now
    
    # Before handler
    log_request(ctx)
    
    # Run the handler
    next_middleware.call(ctx)
    
    # After handler
    duration = Time.now - start_time
    log_completion(ctx, duration)
  rescue => e
    log_error(ctx, e)
    raise
  end
  
  private
  
  def log_request(ctx)
    puts "[#{Time.now}] #{ctx.from.username}: #{ctx.message&.text}"
  end
end
```

3. Rate Limiting

```ruby
class RateLimiter
  def initialize(limit: 10, period: 60)  # 10 requests per minute
    @limit = limit
    @period = period
    @requests = Hash.new { |h, k| h[k] = [] }
  end
  
  def call(ctx, next_middleware)
    user_id = ctx.from.id
    now = Time.now
    
    # Clean old requests
    @requests[user_id].reject! { |time| time < now - @period }
    
    if @requests[user_id].size >= @limit
      ctx.reply "⚠️ Too many requests. Please wait."
      return
    end
    
    @requests[user_id] << now
    next_middleware.call(ctx)
  end
end
```

Async-Aware Middleware

Since Telegem is async, your middleware should be too:

```ruby
class AsyncLogger
  def call(ctx, next_middleware)
    Async do
      # Do async work
      await log_to_database(ctx)
      
      # Continue chain
      await next_middleware.call(ctx)
      
      # More async work
      await update_analytics(ctx)
    end
  end
end
```

---

💾 Session Management

Session Storage Options

```ruby
# 1. Memory (default, development only)
store = Telegem::Session::MemoryStore.new

# 2. Redis (production)
require 'redis'
redis = Redis.new(url: ENV['REDIS_URL'])
store = Telegem::Session::RedisStore.new(redis)

# 3. Custom (database, file, etc.)
class DatabaseStore
  def get(user_id)
    User.find_by(telegram_id: user_id).session_data
  end
  
  def set(user_id, data)
    user = User.find_or_create_by(telegram_id: user_id)
    user.update!(session_data: data)
  end
end
```

Session Data Patterns

Store minimal data:

```ruby
# ❌ Don't store large objects
ctx.session[:user] = large_user_object

# ✅ Store IDs and essential data
ctx.session[:user_id] = user.id
ctx.session[:step] = :collecting_email
ctx.session[:cart] = { item_ids: [1, 2, 3], total: 45.99 }
```

Clear session properly:

```ruby
bot.command('logout') do |ctx|
  # Clear specific keys
  ctx.session.delete(:auth_token)
  ctx.session.delete(:user_id)
  
  # Or clear everything
  ctx.session.clear
  
  ctx.reply "Logged out successfully!"
end
```

Session timeouts:

```ruby
class TimedSession
  def call(ctx, next_middleware)
    # Check if session expired
    if ctx.session[:created_at] && 
       Time.now - ctx.session[:created_at] > 3600  # 1 hour
      ctx.session.clear
      ctx.reply "Session expired. Starting fresh!"
    end
    
    # Update timestamp
    ctx.session[:created_at] ||= Time.now
    
    next_middleware.call(ctx)
  end
end
```

---

🚨 Error Handling Strategies

Global Error Handler

```ruby
bot.error do |error, ctx|
  case error
  when Telegem::APIError
    # Telegram API errors (invalid token, rate limit)
    ctx.reply "⚠️ API Error: #{error.message}"
    log_to_sentry(error, ctx)
    
  when Net::OpenTimeout, SocketError
    # Network issues
    ctx.reply "🌐 Connection issue. Try again?"
    
  when => e
    # Unexpected errors
    ctx.reply "❌ Something went wrong. We've been notified."
    
    # Notify developers
    notify_developers(e, ctx)
    
    # Log everything
    logger.error("Unhandled error: #{e.class}: #{e.message}")
    logger.error("Context: #{ctx.raw_update}")
    logger.error(e.backtrace.join("\n"))
  end
end
```

Per-Command Error Handling

```ruby
bot.command('admin') do |ctx|
  begin
    # Risky operation
    result = do_admin_thing(ctx)
    ctx.reply "Success: #{result}"
  rescue PermissionError => e
    ctx.reply "⛔ Permission denied: #{e.message}"
  rescue => e
    ctx.reply "Admin command failed. Check logs."
    raise  # Still goes to global handler
  end
end
```

Recovery Patterns

Retry logic:

```ruby
def with_retries(max_attempts: 3)
  attempts = 0
  
  while attempts < max_attempts
    begin
      return yield
    rescue Net::ReadTimeout => e
      attempts += 1
      sleep(2 ** attempts)  # Exponential backoff
      retry if attempts < max_attempts
    end
  end
  
  raise "Failed after #{max_attempts} attempts"
end

bot.command('fetch') do |ctx|
  with_retries do
    data = fetch_external_api(ctx.message.text)
    ctx.reply "Found: #{data}"
  end
end
```

---

🌐 Webhook Deployment

Production Webhook Setup

```ruby
# config/bot.rb
require 'telegem'

bot = Telegem.new(ENV['TELEGRAM_BOT_TOKEN'])

# Your bot logic here
bot.command('start') { |ctx| ctx.reply "Running on webhook!" }

# For Rack apps (Rails, Sinatra)
use Telegem::Webhook::Middleware, bot

# OR standalone server
if $0 == __FILE__  # Direct execution
  server = bot.webhook_server(
    port: ENV['PORT'] || 3000,
    endpoint: Async::HTTP::Endpoint.parse("https://#{ENV['DOMAIN']}")
  )
  
  # Set webhook automatically
  Async do
    await bot.set_webhook(
      url: "https://#{ENV['DOMAIN']}/webhook/#{bot.token}",
      certificate: ENV['SSL_CERT_PATH']  # Optional for self-signed
    )
    
    server.run
  end
end
```

Nginx Configuration

```nginx
# For webhook endpoint
location /webhook/ {
    proxy_pass http://localhost:3000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    
    # Telegram requires these timeouts
    proxy_connect_timeout 90;
    proxy_send_timeout 90;
    proxy_read_timeout 90;
}
```

SSL Configuration

```bash
# Let's Encrypt for production
certbot certonly --nginx -d yourdomain.com

# Self-signed for testing (Telegram requires SSL for webhooks)
openssl req -newkey rsa:2048 -sha256 -nodes \
  -keyout private.key -x509 -days 365 \
  -out cert.pem -subj "/C=US/ST=State/L=City/O=Org/CN=yourdomain.com"
```

Health Checks

```ruby
# Add to your webhook server
bot.on(:health) do
  [200, { 'Content-Type' => 'application/json' }, 
   { status: 'ok', time: Time.now.to_i }.to_json]
end
```

---

🧪 Testing Your Bot

Unit Testing Scenes

```ruby
# test/scenes/registration_scene_test.rb
require 'test_helper'

class RegistrationSceneTest < Minitest::Test
  def setup
    @bot = Telegem.new('test_token')
    @bot.scene :registration do
      step :ask_name { |ctx| ctx.reply "What's your name?" }
      step :save_name { |ctx| ctx.session[:name] = ctx.message.text }
    end
  end
  
  def test_scene_flow
    # Mock context
    ctx = Minitest::Mock.new
    ctx.expect(:reply, nil, ["What's your name?"])
    ctx.expect(:session, {})
    
    # Trigger scene
    scene = @bot.scenes[:registration]
    scene.enter(ctx)
    
    assert ctx.verify
  end
end
```

Integration Testing

```ruby
# test/integration/bot_test.rb
require 'test_helper'

class BotIntegrationTest < Minitest::Test
  def test_command_flow
    # Start bot in test mode
    bot = Telegem.new('test_token')
    
    # Capture replies
    replies = []
    bot.command('test') { |ctx| replies << ctx.reply("Working!") }
    
    # Simulate update
    update = {
      'update_id' => 1,
      'message' => {
        'message_id' => 1,
        'from' => { 'id' => 123, 'first_name' => 'Test' },
        'chat' => { 'id' => 456 },
        'text' => '/test'
      }
    }
    
    # Process update
    bot.process(update)
    
    assert_equal 1, replies.size
    assert_includes replies.first, "Working!"
  end
end
```

Mocking Telegram API

```ruby
# spec/spec_helper.rb
RSpec.configure do |config|
  config.before(:each) do
    # Stub Telegram API calls
    allow_any_instance_of(Telegem::API::Client).to receive(:call) do |_, method, params|
      case method
      when 'getMe'
        { 'ok' => true, 'result' => { 'username' => 'test_bot' } }
      when 'sendMessage'
        { 'ok' => true, 'result' => { 'message_id' => 1 } }
      end
    end
  end
end
```

---

⚡ Performance Tips

1. Database Connections

```ruby
class DatabaseMiddleware
  def initialize(pool_size: 5)
    @pool = ConnectionPool.new(size: pool_size) do
      ActiveRecord::Base.connection_pool.checkout
    end
  end
  
  def call(ctx, next_middleware)
    @pool.with do |conn|
      # Use connection within this block
      ctx.db = conn
      next_middleware.call(ctx)
    end
  end
end
```

2. Caching Frequently Used Data

```ruby
class CacheMiddleware
  def initialize(ttl: 300)  # 5 minutes
    @cache = {}
    @ttl = ttl
  end
  
  def call(ctx, next_middleware)
    # Cache user data
    user_key = "user:#{ctx.from.id}"
    
    if cached = @cache[user_key]&.[](:data)
      ctx.cached_user = cached
    else
      # Fetch and cache
      ctx.cached_user = fetch_user(ctx.from.id)
      @cache[user_key] = { data: ctx.cached_user, expires: Time.now + @ttl }
    end
    
    # Clean expired cache
    cleanup_cache
    
    next_middleware.call(ctx)
  end
end
```

3. Batch Operations

```ruby
# Instead of sending one-by-one
messages.each { |msg| ctx.reply(msg) }  # ❌ Slow

# Batch when possible
Async do
  tasks = messages.map do |msg|
    Async { ctx.reply(msg) }
  end
  await_all(tasks)  # ✅ Faster
end
```

4. Monitor Performance

```ruby
class PerformanceMonitor
  def call(ctx, next_middleware)
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    
    next_middleware.call(ctx)
    
    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
    
    if duration > 1.0  # More than 1 second
      logger.warn("Slow handler: #{duration.round(2)}s for #{ctx.message&.text}")
    end
    
    # Record metrics
    record_metric('handler_duration', duration)
  end
end
```

---

🎯 Next Steps

You're ready to build production bots! Here's what to explore next:

1. Database Integration - Connect to PostgreSQL, Redis
2. Background Jobs - Use Sidekiq for heavy processing
3. Monitoring - Add New Relic, Sentry, or Datadog
4. CI/CD - Automate testing and deployment
5. Scaling - Run multiple bot instances behind a load balancer

Remember: The best way to learn is to build something real. Pick a project and start coding!

---

📚 Additional Resources

• Telegram Bot API Reference
• Async Ruby Documentation
• Example Bots Repository
• Community Forum

---

Happy Building! Your journey from library user to expert contributor starts with the next bot you create. 🚀
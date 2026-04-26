# Session Management

Sessions persist data between updates, enabling stateful conversations and user preferences. Telegem supports multiple storage backends with automatic loading and saving.

## How Sessions Work

- Sessions are user-specific key-value stores
- Data persists across messages and bot restarts
- Automatic loading before handlers, saving after
- TTL (time-to-live) support for automatic cleanup

## Basic Usage

```ruby
bot.command('start') do |ctx|
  ctx.session[:visit_count] ||= 0
  ctx.session[:visit_count] += 1

  ctx.reply("Visit ##{ctx.session[:visit_count]}")
end

bot.command('set_name') do |ctx|
  name = ctx.command_args
  ctx.session[:name] = name
  ctx.reply("Name set to #{name}")
end

bot.command('my_name') do |ctx|
  name = ctx.session[:name] || 'unknown'
  ctx.reply("Your name is #{name}")
end
```

## Session Storage Backends

### Memory Store (Development)

```ruby
# Default store
store = Telegem::Session::MemoryStore.new

bot = Telegem.new('TOKEN', session_store: store)
```

Features:
- Fast in-memory storage
- No persistence across restarts
- Automatic cleanup with TTL
- Good for development/testing

### Redis Store (Production)

```ruby
require 'redis'

redis = Redis.new(url: ENV['REDIS_URL'])
store = Telegem::Session::RedisStore.new(redis)

bot = Telegem.new('TOKEN', session_store: store)
```

Features:
- Persistent across deployments
- Scalable and fast
- Automatic serialization
- Redis clustering support

### Custom Store

```ruby
class DatabaseStore
  def initialize(db_connection)
    @db = db_connection
  end

  def get(user_id)
    data = @db.query("SELECT session_data FROM sessions WHERE user_id = ?", user_id)
    data ? JSON.parse(data) : {}
  end

  def set(user_id, data)
    json_data = data.to_json
    @db.execute("INSERT OR REPLACE INTO sessions (user_id, session_data) VALUES (?, ?)", user_id, json_data)
  end
end

store = DatabaseStore.new(my_db_connection)
bot = Telegem.new('TOKEN', session_store: store)
```

## Session Configuration

### Memory Store Options

```ruby
store = Telegem::Session::MemoryStore.new(
  default_ttl: 3600,        # 1 hour default TTL
  cleanup_interval: 300,    # Cleanup every 5 minutes
  backup_path: './sessions.json',  # Backup file path
  backup_interval: 60       # Backup every minute
)
```

### Redis Store Options

```ruby
store = Telegem::Session::RedisStore.new(
  redis: redis_client,
  key_prefix: 'mybot:',     # Key prefix
  ttl: 86400               # 24 hours TTL
)
```

## Session Data Types

Sessions can store any JSON-serializable data:

```ruby
# Simple values
ctx.session[:name] = "John"
ctx.session[:age] = 25
ctx.session[:active] = true

# Complex objects
ctx.session[:preferences] = {
  theme: 'dark',
  language: 'en',
  notifications: true
}

# Arrays
ctx.session[:favorites] = ['item1', 'item2']

# Dates (as timestamps)
ctx.session[:last_login] = Time.now.to_i
```

## Session Operations

### Reading Data

```ruby
# Safe access with defaults
name = ctx.session[:name] || 'Anonymous'
count = ctx.session.fetch(:count, 0)

# Check existence
if ctx.session.key?(:user_data)
  # Data exists
end

# Get all keys
keys = ctx.session.keys
```

### Modifying Data

```ruby
# Set values
ctx.session[:key] = value

# Update existing data
ctx.session[:count] += 1
ctx.session[:list] << new_item

# Delete data
ctx.session.delete(:temp_key)

# Clear all data
ctx.session.clear
```

### Atomic Operations

```ruby
# Increment with default
ctx.session[:counter] ||= 0
ctx.session[:counter] += 1

# Array operations
ctx.session[:items] ||= []
ctx.session[:items] << 'new_item'

# Hash operations
ctx.session[:user] ||= {}
ctx.session[:user][:last_seen] = Time.now.to_i
```

## Session Lifecycle

### Automatic Loading

Session data loads automatically before each handler:

```ruby
bot.use Telegem::Session::Middleware.new(store)
# Sessions load here
# Handler executes
# Sessions save here
```

### Manual Control

```ruby
# Force save
ctx.session[:data] = 'value'
# Automatically saved after handler

# Access raw session data
raw_data = ctx.session.to_h
```

## TTL and Expiration

### Setting TTL

```ruby
# Per key TTL (memory store)
ctx.session.set_with_ttl(:temp_data, 'value', ttl: 300)  # 5 minutes

# Global TTL
store = Telegem::Session::MemoryStore.new(default_ttl: 3600)
```

### Expiration Handling

```ruby
# Check if key exists and not expired
if ctx.session.key?(:temp_data)
  # Use data
else
  # Data expired, handle gracefully
end
```

## Session Security

### Data Sanitization

```ruby
# Don't store sensitive data
# BAD
ctx.session[:password] = user_input

# GOOD - store user ID, look up in secure storage
ctx.session[:user_id] = verified_user_id
```

### Session Hijacking Protection

```ruby
# Validate user identity
bot.use do |ctx, next_middleware|
  if ctx.from&.id != ctx.session[:verified_user_id]
    ctx.session.clear  # Clear suspicious session
  end
  next_middleware.call(ctx)
end
```

## Session Best Practices

### Use Appropriate Data Types

```ruby
# Good: store IDs, not objects
ctx.session[:user_id] = user.id
ctx.session[:chat_id] = chat.id

# Bad: store large objects
ctx.session[:user_object] = user  # Large, changes frequently
```

### Implement Cleanup

```ruby
# Clean up old data
bot.command('logout') do |ctx|
  ctx.session.clear
  ctx.reply("Logged out")
end

# Periodic cleanup for memory store
store = Telegem::Session::MemoryStore.new(
  default_ttl: 86400,  # 24 hours
  cleanup_interval: 3600  # Cleanup hourly
)
```

### Handle Session Errors

```ruby
bot.use do |ctx, next_middleware|
  begin
    next_middleware.call(ctx)
  rescue => e
    ctx.logger.error("Session error: #{e.message}")
    # Continue without session
  end
end
```

### Monitor Session Usage

```ruby
# Log session size
bot.use do |ctx, next_middleware|
  next_middleware.call(ctx)

  if ctx.session.size > 100
    ctx.logger.warn("Large session for user #{ctx.from&.id}: #{ctx.session.size} keys")
  end
end
```

## Advanced Session Patterns

### User Preferences

```ruby
def get_user_preference(ctx, key, default = nil)
  ctx.session[:preferences] ||= {}
  ctx.session[:preferences][key] || default
end

def set_user_preference(ctx, key, value)
  ctx.session[:preferences] ||= {}
  ctx.session[:preferences][key] = value
end

bot.command('set_theme') do |ctx|
  theme = ctx.command_args
  set_user_preference(ctx, :theme, theme)
  ctx.reply("Theme set to #{theme}")
end
```

### Conversation State

```ruby
bot.command('quiz') do |ctx|
  ctx.session[:quiz] = {
    active: true,
    question: 1,
    score: 0,
    answers: []
  }
  ctx.reply("Quiz started! Question 1...")
end

bot.hears(/.+/) do |ctx|
  quiz = ctx.session[:quiz]
  if quiz&.[](:active)
    # Process quiz answer
    process_quiz_answer(ctx, quiz, ctx.message.text)
  end
end
```

### Rate Limiting

```ruby
bot.use do |ctx, next_middleware|
  user_id = ctx.from&.id
  return next_middleware.call(ctx) unless user_id

  key = "rate_limit:#{user_id}"
  ctx.session[key] ||= { count: 0, window_start: Time.now.to_i }

  window_size = 60  # 1 minute
  max_requests = 10

  now = Time.now.to_i
  rate_data = ctx.session[key]

  # Reset window if needed
  if now - rate_data[:window_start] > window_size
    rate_data[:count] = 0
    rate_data[:window_start] = now
  end

  if rate_data[:count] >= max_requests
    ctx.reply("Rate limit exceeded")
    return
  end

  rate_data[:count] += 1
  next_middleware.call(ctx)
end
```

### Session Migration

```ruby
# Migrate old session format
bot.use do |ctx, next_middleware|
  if ctx.session[:old_format]
    # Migrate data
    ctx.session[:new_format] = transform_old_data(ctx.session[:old_format])
    ctx.session.delete(:old_format)
  end

  next_middleware.call(ctx)
end
```

## Session Storage Implementations

### File-Based Store

```ruby
class FileStore
  def initialize(file_path)
    @file_path = file_path
    @data = load_data
  end

  def get(user_id)
    @data[user_id.to_s] || {}
  end

  def set(user_id, data)
    @data[user_id.to_s] = data
    save_data
  end

  private

  def load_data
    File.exist?(@file_path) ? JSON.parse(File.read(@file_path)) : {}
  end

  def save_data
    File.write(@file_path, @data.to_json)
  end
end
```

### Database Store

```ruby
class PostgresStore
  def initialize(connection_string)
    @db = PG.connect(connection_string)
    create_table
  end

  def get(user_id)
    result = @db.exec_params("SELECT data FROM sessions WHERE user_id = $1", [user_id])
    result.any? ? JSON.parse(result[0]['data']) : {}
  end

  def set(user_id, data)
    json_data = data.to_json
    @db.exec_params(
      "INSERT INTO sessions (user_id, data) VALUES ($1, $2) ON CONFLICT (user_id) DO UPDATE SET data = $2",
      [user_id, json_data]
    )
  end

  private

  def create_table
    @db.exec(%q{
      CREATE TABLE IF NOT EXISTS sessions (
        user_id BIGINT PRIMARY KEY,
        data JSONB NOT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    })
  end
end
```

## Session Monitoring and Debugging

### Session Inspector

```ruby
bot.command('debug_session') do |ctx|
  session_data = ctx.session.to_h
  ctx.reply("Session keys: #{session_data.keys.join(', ')}")
  ctx.reply("Session size: #{session_data.to_json.size} bytes")
end
```

### Session Analytics

```ruby
class SessionAnalyticsMiddleware
  def initialize
    @stats = {}
  end

  def call(ctx, next_middleware)
    user_id = ctx.from&.id
    return next_middleware.call(ctx) unless user_id

    @stats[user_id] ||= { messages: 0, session_size: 0 }
    @stats[user_id][:messages] += 1
    @stats[user_id][:session_size] = ctx.session.size

    next_middleware.call(ctx)
  end

  def report
    total_users = @stats.size
    total_messages = @stats.values.sum { |s| s[:messages] }
    avg_session_size = @stats.values.sum { |s| s[:session_size] } / total_users.to_f

    puts "Session Analytics:"
    puts "Total users: #{total_users}"
    puts "Total messages: #{total_messages}"
    puts "Avg session size: #{avg_session_size.round(2)}"
  end
end
```

## Performance Considerations

### Memory Usage

- Large sessions increase memory usage
- Use TTL to automatically clean up
- Monitor session sizes in production

### Database Performance

- Index user_id in database stores
- Use connection pooling for database stores
- Consider caching frequently accessed data

### Redis Optimization

```ruby
# Use Redis pipelines for bulk operations
redis.pipelined do
  redis.set("session:#{user_id}", data.to_json)
  redis.expire("session:#{user_id}", ttl)
end
```

Sessions are essential for creating stateful, personalized bot experiences. Choose the right storage backend and use sessions wisely to maintain good performance.</content>
<parameter name="filePath">/home/slick/telegem/docs/sessions.md
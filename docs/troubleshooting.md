# Troubleshooting

Common issues and solutions when working with Telegem bots.

## Bot Not Responding

### Check Bot Token

**Problem:** Bot doesn't respond to messages.

**Symptoms:**
- Commands are sent but no response
- Bot appears offline

**Solutions:**

1. **Verify token validity:**
```ruby
# Test token
bot = Telegem.new(token: 'YOUR_TOKEN')
me = bot.api.call('getMe')
puts me.inspect
```

2. **Check token format:**
   - Should start with bot ID
   - Format: `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`

3. **Ensure bot is not blocked:**
   - Check @BotFather for bot status
   - Verify token hasn't expired

### Check Polling/Webhook Setup

**Problem:** Bot receives messages but doesn't process them.

**For Polling:**
```ruby
bot = Telegem.new(token: 'YOUR_TOKEN')

# Add debug logging
bot.logger = Logger.new(STDOUT)
bot.logger.level = Logger::DEBUG

bot.command('test') do |ctx|
  ctx.reply('Working!')
end

bot.start_polling
```

**For Webhooks:**
```ruby
# Check webhook info
webhook_info = bot.api.call('getWebhookInfo')
puts webhook_info.inspect

# Delete webhook if needed
bot.api.call('deleteWebhook')

# Then start polling
bot.start_polling
```

### Check Network Connectivity

**Problem:** Connection issues to Telegram API.

**Test connectivity:**
```ruby
require 'net/http'

uri = URI('https://api.telegram.org/botYOUR_TOKEN/getMe')
response = Net::HTTP.get(uri)
puts response
```

**Common issues:**
- Firewall blocking outbound connections
- DNS resolution problems
- Proxy configuration needed

## Handler Not Triggering

### Command Handler Issues

**Problem:** `/command` doesn't work.

**Check:**
1. **Command registration:**
```ruby
bot.command('test') do |ctx|
  puts "Command received"  # Add debug
  ctx.reply('Working!')
end
```

2. **Command format:**
   - Must start with `/`
   - Case-sensitive
   - No spaces in command name

3. **Bot permissions:**
   - Bot must be added to chat
   - Bot must have message reading permissions

### Hears Handler Issues

**Problem:** Pattern matching doesn't work.

**Check regex patterns:**
```ruby
# Test pattern
pattern = /^hello/
text = "hello world"
puts pattern.match?(text)  # Should be true

bot.hears(/^hello/) do |ctx|
  ctx.reply('Hi!')
end
```

**Common mistakes:**
- Forgetting word boundaries: `/^hello/` vs `/hello/`
- Case sensitivity: `/hello/i` for case-insensitive
- Special characters need escaping

### Callback Query Issues

**Problem:** Inline keyboard buttons don't work.

**Check:**
1. **Callback data format:**
```ruby
bot.callback_query('button1') do |ctx|
  ctx.answer_callback_query('Clicked!')
end
```

2. **Button setup:**
```ruby
keyboard = Telegem.inline_keyboard do |kb|
  kb.button('Click me', callback_data: 'button1')
end
```

3. **Message ownership:**
   - Callback queries only work for messages sent by the bot

## Session Issues

### Session Not Persisting

**Problem:** Session data lost between messages.

**Check middleware setup:**
```ruby
# Ensure middleware is loaded
bot.use Telegem::Session::Middleware.new

# Use memory store for testing
bot.session_store = Telegem::Session::MemoryStore.new
```

**For Redis:**
```ruby
require 'redis'
bot.session_store = Telegem::Session::RedisStore.new(ENV['REDIS_URL'])
```

### Session Store Errors

**Problem:** Database connection issues.

**Check connection:**
```ruby
begin
  bot.session_store.test_connection
  puts "Session store connected"
rescue => e
  puts "Session store error: #{e.message}"
end
```

## API Errors

### Rate Limiting

**Problem:** `429 Too Many Requests` errors.

**Solutions:**
1. **Implement rate limiting:**
```ruby
bot.use do |ctx, next_middleware|
  # Simple rate limit
  user_id = ctx.from.id
  key = "rate_limit:#{user_id}"

  if bot.session_store.get(key)
    ctx.reply('Please wait before sending another message')
    return
  end

  bot.session_store.set(key, '1', ttl: 1)  # 1 second limit
  next_middleware.call(ctx)
end
```

2. **Use exponential backoff:**
```ruby
def api_call_with_retry(method, params, retries = 3)
  begin
    bot.api.call(method, params)
  rescue Telegem::API::APIError => e
    if e.code == 429 && retries > 0
      sleep_time = 2 ** (4 - retries)  # Exponential backoff
      sleep(sleep_time)
      api_call_with_retry(method, params, retries - 1)
    else
      raise
    end
  end
end
```

### Invalid Parameters

**Problem:** `400 Bad Request` errors.

**Common causes:**
- Invalid chat_id
- Malformed message text
- Unsupported file format
- Missing required parameters

**Debug:**
```ruby
begin
  result = bot.api.call('sendMessage', chat_id: chat_id, text: text)
rescue Telegem::API::APIError => e
  puts "API Error: #{e.message}"
  puts "Chat ID: #{chat_id}"
  puts "Text: #{text.inspect}"
end
```

### File Upload Issues

**Problem:** File sending fails.

**Check:**
1. **File size limits:**
   - Documents: 20MB
   - Photos: 10MB
   - Videos: 50MB

2. **File format:**
```ruby
# Check file type
file_path = '/path/to/file'
mime_type = `file --mime-type -b #{file_path}`.strip

# Send appropriate type
if mime_type.start_with?('image/')
  bot.api.call('sendPhoto', chat_id: chat_id, photo: File.open(file_path))
elsif mime_type.start_with?('video/')
  bot.api.call('sendVideo', chat_id: chat_id, video: File.open(file_path))
else
  bot.api.call('sendDocument', chat_id: chat_id, document: File.open(file_path))
end
```

## Webhook Issues

### Webhook Not Receiving Updates

**Problem:** Webhook URL not getting requests.

**Check:**
1. **URL accessibility:**
```bash
curl -X POST https://your-domain.com/webhook \
  -H "Content-Type: application/json" \
  -d '{"update_id": 1}'
```

2. **SSL certificate:**
```bash
openssl s_client -connect your-domain.com:443 -servername your-domain.com
```

3. **Webhook registration:**
```ruby
webhook_info = bot.api.call('getWebhookInfo')
puts webhook_info.inspect
```

### Webhook Server Errors

**Problem:** Webhook server crashes.

**Check logs:**
```ruby
# Add error handling
bot.error do |error, ctx|
  puts "Error: #{error.message}"
  puts error.backtrace
end
```

**Common issues:**
- Port already in use
- SSL certificate problems
- Memory leaks in handlers

## Scene Issues

### Scene Not Starting

**Problem:** `enter_scene` doesn't work.

**Check:**
1. **Scene definition:**
```ruby
bot.scene('test_scene') do |scene|
  scene.step('step1') do |ctx|
    # Handler code
  end
end
```

2. **Scene entry:**
```ruby
bot.command('start_scene') do |ctx|
  ctx.enter_scene('test_scene')
end
```

### Scene State Lost

**Problem:** Scene progress lost.

**Check session persistence:**
```ruby
# Ensure session middleware
bot.use Telegem::Session::Middleware.new

# Check session data
bot.command('debug') do |ctx|
  puts ctx.session.inspect
end
```

## Performance Issues

### High Memory Usage

**Problem:** Bot consumes too much memory.

**Check:**
1. **Session cleanup:**
```ruby
# Clear old sessions
bot.session_store.cleanup_expired
```

2. **File handling:**
```ruby
# Don't load large files into memory
File.open('large_file') do |file|
  bot.api.call('sendDocument', chat_id: chat_id, document: file)
end
```

### Slow Response Times

**Problem:** Bot responds slowly.

**Profile code:**
```ruby
require 'ruby-prof'

bot.command('profile') do |ctx|
  RubyProf.start

  # Your code here

  result = RubyProf.stop
  printer = RubyProf::FlatPrinter.new(result)
  printer.print(STDOUT)
end
```

**Common bottlenecks:**
- Database queries
- File processing
- External API calls

## Deployment Issues

### Environment Variables

**Problem:** Configuration not loading.

**Check:**
```bash
# Print environment
puts ENV['TELEGRAM_BOT_TOKEN'] ? 'Token set' : 'Token missing'
puts ENV['REDIS_URL'] ? 'Redis set' : 'Redis missing'
```

### Process Management

**Problem:** Bot stops unexpectedly.

**Check logs:**
```bash
# Systemd logs
journalctl -u telegem-bot -f

# Process status
ps aux | grep telegem
```

**Add monitoring:**
```ruby
# Health check endpoint
bot.get('/health') do |ctx|
  ctx.response.body = {
    status: 'ok',
    uptime: Time.now - START_TIME,
    memory: `ps -o rss= -p #{Process.pid}`.to_i
  }.to_json
end
```

## Plugin Issues

### Plugin Loading Errors

**Problem:** Plugin fails to load.

**Check dependencies:**
```ruby
begin
  require 'telegem/plugins/file_extract'
rescue LoadError => e
  puts "Plugin dependency missing: #{e.message}"
  # Install missing gems
end
```

### Plugin Runtime Errors

**Problem:** Plugin throws exceptions.

**Add error handling:**
```ruby
bot.document do |ctx|
  begin
    extractor = Telegem::Plugins::FileExtract.new(ctx.bot, ctx.message.document.file_id)
    result = extractor.extract
    # Process result
  rescue => e
    ctx.logger.error("Plugin error: #{e.message}")
    ctx.reply("File processing failed")
  end
end
```

## Testing Issues

### Test Failures

**Problem:** Tests don't pass.

**Check:**
1. **Mock setup:**
```ruby
# Ensure API is mocked
allow(bot.api).to receive(:call).and_return({'ok' => true})
```

2. **Async operations:**
```ruby
# Wait for async completion
sleep 0.1
```

### Coverage Issues

**Problem:** Low test coverage.

**Check uncovered code:**
```ruby
# Run with coverage
bundle exec rspec --format html
```

## Common Error Messages

### "Bot token is required"

**Cause:** Token not provided or invalid.

**Fix:**
```ruby
bot = Telegem.new(token: ENV['TELEGRAM_BOT_TOKEN'])
```

### "Invalid bot token"

**Cause:** Malformed token.

**Fix:** Get new token from @BotFather.

### "Chat not found"

**Cause:** Invalid chat_id.

**Fix:** Use correct chat ID or username.

### "Message is too long"

**Cause:** Message exceeds 4096 characters.

**Fix:** Split long messages.

### "Bad Request: query is too old"

**Cause:** Callback query answered too late.

**Fix:** Answer callback queries immediately.

### "Conflict: terminated by other getUpdates request"

**Cause:** Multiple polling instances.

**Fix:** Stop other bot instances.

## Getting Help

1. **Check documentation:** Review docs/ folder
2. **Search issues:** Check GitHub issues
3. **Enable debug logging:**
```ruby
bot.logger.level = Logger::DEBUG
```
4. **Test with minimal code:**
```ruby
# Minimal test bot
bot = Telegem.new(token: 'YOUR_TOKEN')
bot.command('test') { |ctx| ctx.reply('OK') }
bot.start_polling
```
5. **Check Telegram Bot API status:** https://t.me/botapiupdates

## Debug Checklist

- [ ] Bot token is valid
- [ ] Network connectivity works
- [ ] Handlers are registered
- [ ] Session middleware loaded
- [ ] Error handlers implemented
- [ ] Logs enabled
- [ ] Dependencies installed
- [ ] Environment variables set
- [ ] No conflicting processes
- [ ] SSL certificates valid (webhooks)
- [ ] Rate limits not exceeded
- [ ] File size limits respected

Use this checklist when debugging issues.</content>
<parameter name="filePath">/home/slick/telegem/docs/troubleshooting.md
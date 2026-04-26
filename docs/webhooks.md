# Webhook Deployment

Webhooks provide production-ready deployment for Telegram bots. Unlike polling, webhooks push updates instantly and scale better.

## How Webhooks Work

1. Telegram sends updates to your server URL
2. Server processes updates and responds
3. No need to constantly poll for updates

## Basic Webhook Setup

### Using Built-in Server

```ruby
require 'telegem'

bot = Telegem.new('YOUR_BOT_TOKEN')

# Define handlers
bot.command('start') do |ctx|
  ctx.reply("Hello!")
end

# Start webhook server
server = bot.webhook(port: 3000, host: '0.0.0.0')
server.run
```

### Manual Webhook Setup

```ruby
# Set webhook URL
bot.set_webhook(url: 'https://yourdomain.com/webhook')

# In your web framework (Sinatra example)
post '/webhook' do
  update_data = JSON.parse(request.body.read)
  bot.process(update_data)
  status 200
  body 'OK'
end
```

## Production Deployment

### Heroku Deployment

```ruby
# Gemfile
source 'https://rubygems.org'
gem 'telegem'

# app.rb
require 'telegem'

bot = Telegem.new(ENV['BOT_TOKEN'])

# Bot handlers...

if ENV['RACK_ENV'] == 'production'
  # Production: use webhook
  server = bot.webhook
  server.run
else
  # Development: use polling
  bot.start_polling
end

# Procfile
web: bundle exec ruby app.rb
```

### Docker Deployment

```dockerfile
FROM ruby:3.2-alpine

WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .

EXPOSE 3000
CMD ["ruby", "bot.rb"]
```

```ruby
# bot.rb
bot = Telegem.new(ENV['BOT_TOKEN'])

# Set webhook in production
if ENV['WEBHOOK_URL']
  bot.set_webhook(url: ENV['WEBHOOK_URL'])
end

server = bot.webhook(port: ENV['PORT'] || 3000)
server.run
```

### Railway/Render Deployment

```ruby
# Similar to Heroku
webhook_url = ENV['WEBHOOK_URL'] || "https://#{ENV['DOMAIN']}/webhook"

bot.set_webhook(url: webhook_url)
server = bot.webhook
server.run
```

## SSL/TLS Configuration

Telegram requires HTTPS for webhooks. Telegem supports multiple SSL setups.

### Cloud Platform SSL (Recommended)

```ruby
# For Heroku, Railway, Render, etc.
server = bot.webhook
server.run  # Platform handles SSL
```

### Local SSL Certificates

```ruby
# Create .telegem-ssl file
# cert_path: /path/to/cert.pem
# key_path: /path/to/key.pem

server = bot.webhook
server.run  # Uses local certificates
```

### Manual SSL Configuration

```ruby
require 'openssl'

ssl_context = OpenSSL::SSL::SSLContext.new
ssl_context.cert = OpenSSL::X509::Certificate.new(File.read('cert.pem'))
ssl_context.key = OpenSSL::PKey::RSA.new(File.read('key.pem'))

server = bot.webhook(ssl_context: ssl_context)
server.run
```

## Webhook Security

### Secret Token

```ruby
# Generate secure token
require 'securerandom'
secret_token = SecureRandom.hex(16)

server = bot.webhook(secret_token: secret_token)

# Webhook URL: https://yourdomain.com/webhook/SECRET_TOKEN
```

### IP Whitelisting

```ruby
# Only accept from Telegram IPs
ALLOWED_IPS = [
  '149.154.160.0/20',
  '91.108.4.0/22'
  # Add other Telegram IP ranges
]

before do
  client_ip = request.ip
  unless ALLOWED_IPS.any? { |range| IPAddr.new(range).include?(client_ip) }
    halt 403, 'Forbidden'
  end
end
```

### Request Validation

```ruby
post '/webhook/:token' do
  provided_token = params[:token]
  expected_token = ENV['WEBHOOK_SECRET']

  if provided_token != expected_token
    halt 401, 'Unauthorized'
  end

  # Process update...
end
```

## Webhook Management

### Setting Webhooks

```ruby
# Basic setup
bot.set_webhook(url: 'https://example.com/webhook')

# With options
bot.set_webhook(
  url: 'https://example.com/webhook',
  max_connections: 40,
  allowed_updates: ['message', 'callback_query'],
  secret_token: 'your_secret'
)
```

### Checking Webhook Status

```ruby
info = bot.get_webhook_info
puts "Webhook URL: #{info.url}"
puts "Pending updates: #{info.pending_update_count}"
puts "Last error: #{info.last_error_message}"
```

### Removing Webhooks

```ruby
bot.delete_webhook
```

## Error Handling

### Webhook Errors

```ruby
# Handle processing errors
server = bot.webhook do |error, update|
  logger.error("Webhook error: #{error.message}")
  logger.error("Failed update: #{update}")
end
```

### Timeout Handling

```ruby
# Set processing timeout
bot = Telegem.new('TOKEN', timeout: 30)

# Handle slow requests
server = bot.webhook(timeout: 25)  # Process within 25 seconds
```

### Health Checks

```ruby
# Add health endpoint
server = bot.webhook do
  get '/health' do
    content_type :json
    {
      status: 'ok',
      timestamp: Time.now.to_i,
      version: Telegem::VERSION
    }.to_json
  end
end
```

## Scaling Considerations

### Multiple Workers

```ruby
# Use web server with multiple processes
# Puma, Unicorn, or similar

workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = Integer(ENV['MAX_THREADS'] || 5)
threads threads_count, threads_count

preload_app!

rackup DefaultRackup
port ENV['PORT'] || 3000
environment ENV['RACK_ENV'] || 'development'
```

### Load Balancing

```ruby
# Multiple bot instances behind load balancer
# Each instance processes updates independently
# Use Redis for shared session storage

bot = Telegem.new('TOKEN', session_store: redis_store)
```

### Rate Limiting

```ruby
# Implement rate limiting middleware
bot.use do |ctx, next_middleware|
  # Rate limiting logic
  next_middleware.call(ctx)
end
```

## Monitoring and Logging

### Request Logging

```ruby
server = bot.webhook do
  use Rack::CommonLogger, logger
end
```

### Performance Monitoring

```ruby
# Log request duration
bot.use do |ctx, next_middleware|
  start = Time.now
  next_middleware.call(ctx)
  duration = Time.now - start

  if duration > 1.0
    logger.warn("Slow request: #{duration}s for #{ctx.update_type}")
  end
end
```

### Error Tracking

```ruby
# Send errors to monitoring service
bot.error do |error, ctx|
  # Send to Sentry, Rollbar, etc.
  error_tracker.capture(error, context: ctx)
end
```

## Development vs Production

### Development Setup

```ruby
# Use polling in development
if ENV['RACK_ENV'] == 'development'
  bot.start_polling
else
  # Production webhook
  webhook_url = ENV['WEBHOOK_URL']
  bot.set_webhook(url: webhook_url)
  server = bot.webhook
  server.run
end
```

### Local Development with ngrok

```bash
# Install ngrok
npm install -g ngrok

# Expose local server
ngrok http 3000

# Set webhook to ngrok URL
bot.set_webhook(url: 'https://abc123.ngrok.io/webhook')
```

## Common Issues

### Webhook Not Receiving Updates

```ruby
# Check webhook info
info = bot.get_webhook_info
puts info.inspect

# Common issues:
# - Wrong URL
# - SSL certificate issues
# - Server not responding
# - Firewall blocking requests
```

### SSL Certificate Errors

```ruby
# Telegram requires valid SSL
# Use services like Let's Encrypt
# Or cloud platforms with built-in SSL
```

### Timeout Errors

```ruby
# Increase timeout
bot = Telegem.new('TOKEN', timeout: 60)

# Optimize handler performance
# Use async operations for I/O
```

### High Memory Usage

```ruby
# Monitor memory usage
# Use session TTL
# Implement cleanup routines
```

## Webhook Best Practices

1. **Use HTTPS**: Always use SSL/TLS
2. **Validate Requests**: Check secret tokens and IPs
3. **Handle Errors**: Implement proper error handling
4. **Monitor Performance**: Track response times and errors
5. **Scale Horizontally**: Use multiple instances behind load balancer
6. **Use Timeouts**: Prevent hanging requests
7. **Log Everything**: Comprehensive logging for debugging

## Alternative Deployment Options

### Serverless Functions

```javascript
// Vercel/Netlify function
export default async function handler(req, res) {
  if (req.method === 'POST') {
    const update = req.body;
    // Process update with Telegem
    res.status(200).json({ ok: true });
  }
}
```

### Docker Compose

```yaml
version: '3'
services:
  bot:
    build: .
    ports:
      - "3000:3000"
    environment:
      - BOT_TOKEN=${BOT_TOKEN}
      - REDIS_URL=redis://redis:6379
    depends_on:
      - redis

  redis:
    image: redis:alpine
```

Webhooks provide reliable, scalable deployment for production Telegram bots. Choose the right hosting platform and configure SSL properly for best results.</content>
<parameter name="filePath">/home/slick/telegem/docs/webhooks.md
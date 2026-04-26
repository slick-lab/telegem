# Deployment

Deploy Telegem bots to production with proper configuration, monitoring, and scaling.

## Environment Setup

### Production Environment Variables

```bash
# Required
export TELEGRAM_BOT_TOKEN="your_bot_token_here"
export TELEGEM_ENV="production"

# Optional
export REDIS_URL="redis://localhost:6379/0"
export LOG_LEVEL="info"
export WEBHOOK_URL="https://your-domain.com/webhook"
export SSL_CERT_PATH="/path/to/cert.pem"
export SSL_KEY_PATH="/path/to/key.pem"
```

### Ruby Version Management

```ruby
# Gemfile
ruby '3.1.0'

# Use specific Ruby version
source 'https://rubygems.org'

gem 'telegem'
```

### System Dependencies

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install ruby ruby-dev build-essential redis-server

# macOS
brew install ruby redis

# Install bundler
gem install bundler
```

## Webhook Deployment

### Basic Webhook Setup

```ruby
require 'telegem'

bot = Telegem.new(token: ENV['TELEGRAM_BOT_TOKEN'])

# Configure webhook
bot.webhook_url = ENV['WEBHOOK_URL']
bot.webhook_cert = ENV['SSL_CERT_PATH'] if ENV['SSL_CERT_PATH']

# Add handlers
bot.command('start') do |ctx|
  ctx.reply("Bot is running!")
end

# Start webhook server
bot.start_webhook
```

### SSL Configuration

```ruby
# Self-signed certificate (development only)
bot.webhook_cert = './ssl/cert.pem'
bot.webhook_key = './ssl/key.pem'

# Let's Encrypt certificate (production)
bot.webhook_cert = '/etc/letsencrypt/live/yourdomain.com/fullchain.pem'
bot.webhook_key = '/etc/letsencrypt/live/yourdomain.com/privkey.pem'
```

### Webhook Server Configuration

```ruby
# Custom server configuration
server = Telegem::Webhook::Server.new(
  host: '0.0.0.0',
  port: 8443,
  ssl_cert: cert_path,
  ssl_key: key_path,
  max_connections: 100,
  timeout: 30
)

bot.start_webhook(server: server)
```

## Polling Deployment

### Long-Running Process

```ruby
require 'telegem'

bot = Telegem.new(token: ENV['TELEGRAM_BOT_TOKEN'])

# Configure polling
bot.poll_timeout = 30
bot.poll_limit = 100

# Add handlers
bot.command('ping') do |ctx|
  ctx.reply("Pong!")
end

# Start polling
bot.start_polling
```

### Process Management

```bash
# systemd service file (/etc/systemd/system/telegem-bot.service)
[Unit]
Description=Telegem Bot
After=network.target redis.service

[Service]
Type=simple
User=telegem
WorkingDirectory=/path/to/bot
ExecStart=/usr/local/bin/bundle exec ruby bot.rb
Restart=always
RestartSec=5
Environment=TELEGEM_ENV=production

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start service
sudo systemctl enable telegem-bot
sudo systemctl start telegem-bot
sudo systemctl status telegem-bot
```

## Docker Deployment

### Dockerfile

```dockerfile
FROM ruby:3.1-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and install dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test

# Copy application code
COPY . .

# Create non-root user
RUN useradd --create-home --shell /bin/bash telegem
USER telegem

# Expose port for webhook
EXPOSE 8443

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8443/health || exit 1

# Start the bot
CMD ["bundle", "exec", "ruby", "bot.rb"]
```

### Docker Compose

```yaml
version: '3.8'

services:
  bot:
    build: .
    environment:
      - TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
      - REDIS_URL=redis://redis:6379/0
      - TELEGEM_ENV=production
    depends_on:
      - redis
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    restart: unless-stopped

volumes:
  redis_data:
```

### Multi-Stage Build

```dockerfile
# Build stage
FROM ruby:3.1-slim as builder

RUN apt-get update && apt-get install -y build-essential
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test && bundle clean --force

# Runtime stage
FROM ruby:3.1-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /usr/local/bundle /usr/local/bundle
WORKDIR /app
COPY . .

USER nobody
EXPOSE 8443
CMD ["bundle", "exec", "ruby", "bot.rb"]
```

## Cloud Deployment

### Heroku

```ruby
# Gemfile
source 'https://rubygems.org'
ruby '3.1.0'

gem 'telegem'
gem 'redis'
```

```yaml
# Procfile
web: bundle exec ruby bot.rb
```

```ruby
# bot.rb
require 'telegem'

bot = Telegem.new(token: ENV['TELEGRAM_BOT_TOKEN'])

# Use Redis for sessions
bot.session_store = Telegem::Session::RedisStore.new(ENV['REDIS_URL'])

# Webhook for Heroku
bot.webhook_url = "https://#{ENV['HEROKU_APP_NAME']}.herokuapp.com/webhook"

bot.command('start') do |ctx|
  ctx.reply("Bot deployed on Heroku!")
end

bot.start_webhook
```

```bash
# Deploy
heroku create your-bot-name
heroku config:set TELEGRAM_BOT_TOKEN=your_token_here
git push heroku main
```

### AWS ECS

```json
{
  "family": "telegem-bot",
  "taskRoleArn": "arn:aws:iam::123456789012:role/ecsTaskExecutionRole",
  "executionRoleArn": "arn:aws:iam::123456789012:role/ecsTaskExecutionRole",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "telegem-bot",
      "image": "your-registry/telegem-bot:latest",
      "essential": true,
      "environment": [
        {"name": "TELEGRAM_BOT_TOKEN", "value": "your_token"},
        {"name": "TELEGEM_ENV", "value": "production"}
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/telegem-bot",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

### Google Cloud Run

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: telegem-bot
spec:
  template:
    spec:
      containers:
      - image: gcr.io/your-project/telegem-bot:latest
        env:
        - name: TELEGRAM_BOT_TOKEN
          value: "your_token"
        - name: TELEGEM_ENV
          value: "production"
        ports:
        - containerPort: 8443
        resources:
          limits:
            cpu: 1000m
            memory: 512Mi
```

### Railway

```toml
# railway.toml
[build]
builder = "dockerfile"

[deploy]
healthcheckPath = "/health"
healthcheckTimeout = 300
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 10
```

## Monitoring and Logging

### Structured Logging

```ruby
require 'logger'

class ProductionLogger
  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = ENV['LOG_LEVEL'] == 'debug' ? Logger::DEBUG : Logger::INFO
    @logger.formatter = proc do |severity, datetime, progname, msg|
      {
        timestamp: datetime.iso8601,
        level: severity,
        message: msg,
        service: 'telegem-bot'
      }.to_json + "\n"
    end
  end

  def info(msg); @logger.info(msg); end
  def error(msg); @logger.error(msg); end
  def debug(msg); @logger.debug(msg); end
end

bot.logger = ProductionLogger.new
```

### Health Checks

```ruby
bot.get('/health') do |ctx|
  # Check database connectivity
  redis_ping = begin
    bot.session_store.redis.ping == 'PONG'
  rescue
    false
  end

  # Check bot API
  api_check = begin
    bot.api.call('getMe')['ok']
  rescue
    false
  end

  status = redis_ping && api_check ? 200 : 503
  ctx.response.status = status
  ctx.response.body = {
    status: status == 200 ? 'healthy' : 'unhealthy',
    timestamp: Time.now.to_i,
    checks: {
      redis: redis_ping,
      telegram_api: api_check
    }
  }.to_json
end
```

### Metrics Collection

```ruby
class MetricsMiddleware
  def initialize
    @metrics = {
      requests_total: 0,
      errors_total: 0,
      response_time_sum: 0
    }
  end

  def call(ctx, next_middleware)
    start_time = Time.now

    begin
      @metrics[:requests_total] += 1
      next_middleware.call(ctx)
    rescue => e
      @metrics[:errors_total] += 1
      raise
    ensure
      response_time = Time.now - start_time
      @metrics[:response_time_sum] += response_time
    end
  end

  def stats
    avg_response_time = @metrics[:requests_total] > 0 ?
      @metrics[:response_time_sum] / @metrics[:requests_total] : 0

    {
      requests_total: @metrics[:requests_total],
      errors_total: @metrics[:errors_total],
      avg_response_time: avg_response_time
    }
  end
end

metrics = MetricsMiddleware.new
bot.use metrics

bot.get('/metrics') do |ctx|
  ctx.response.body = metrics.stats.to_json
end
```

## Scaling Considerations

### Horizontal Scaling

```ruby
# Multiple bot instances
instances = ENV['INSTANCES']&.to_i || 1

instances.times do |i|
  fork do
    bot = Telegem.new(token: ENV['TELEGRAM_BOT_TOKEN'])
    # Configure instance-specific settings
    bot.instance_id = i
    bot.start_polling
  end
end

Process.waitall
```

### Load Balancing

```ruby
# Use Redis for distributed sessions
bot.session_store = Telegem::Session::RedisStore.new(ENV['REDIS_URL'])

# Distributed locks for critical operations
require 'redis-mutex'

bot.command('critical') do |ctx|
  Redis::Mutex.with_lock('critical_operation') do
    # Critical operation
    ctx.reply("Operation completed")
  end
end
```

### Database Connection Pooling

```ruby
# For database-backed session stores
bot.session_store = Telegem::Session::DatabaseStore.new(
  pool_size: ENV['DB_POOL_SIZE']&.to_i || 5,
  timeout: 5
)
```

## Security Best Practices

### Environment Variables

```bash
# Never commit secrets
echo ".env" >> .gitignore

# Use strong tokens
export TELEGRAM_BOT_TOKEN="$(openssl rand -hex 32)"
```

### SSL/TLS

```ruby
# Force HTTPS in production
bot.use SSLMiddleware.new if ENV['TELEGEM_ENV'] == 'production'

class SSLMiddleware
  def call(ctx, next_middleware)
    if ctx.request.scheme != 'https'
      ctx.response.status = 301
      ctx.response.headers['Location'] = ctx.request.url.sub('http:', 'https:')
      return
    end
    next_middleware.call(ctx)
  end
end
```

### Input Validation

```ruby
bot.use InputValidationMiddleware.new

class InputValidationMiddleware
  def call(ctx, next_middleware)
    # Sanitize input
    if ctx.text
      ctx.text = sanitize_input(ctx.text)
    end

    # Rate limiting
    if rate_limited?(ctx.from.id)
      ctx.response.status = 429
      return
    end

    next_middleware.call(ctx)
  end

  private

  def sanitize_input(text)
    # Remove dangerous characters
    text.gsub(/[<>'"&]/, '')
  end

  def rate_limited?(user_id)
    # Implement rate limiting logic
    false
  end
end
```

## Performance Optimization

### Connection Pooling

```ruby
# HTTP client configuration
bot.api.http_client = Async::HTTP::Client.new(
  pool_size: 10,
  timeout: 30
)
```

### Caching

```ruby
require 'redis'

class CacheMiddleware
  def initialize(redis_url)
    @redis = Redis.new(url: redis_url)
  end

  def call(ctx, next_middleware)
    cache_key = "response:#{ctx.update.update_id}"

    if cached = @redis.get(cache_key)
      ctx.response.body = cached
      return
    end

    next_middleware.call(ctx)

    # Cache successful responses
    if ctx.response.status == 200
      @redis.setex(cache_key, 300, ctx.response.body) # 5 min cache
    end
  end
end
```

### Background Processing

```ruby
require 'async'

bot.command('heavy_task') do |ctx|
  ctx.reply("Processing in background...")

  Async do
    result = perform_heavy_computation(ctx.text)
    ctx.reply("Result: #{result}")
  end
end
```

## Backup and Recovery

### Database Backups

```bash
# Redis backup script
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
redis-cli --rdb /backup/redis_$DATE.rdb

# Clean old backups
find /backup -name "redis_*.rdb" -mtime +7 -delete
```

### Configuration Backup

```ruby
# Backup bot configuration
task :backup do
  config = {
    token: ENV['TELEGRAM_BOT_TOKEN'],
    webhook_url: ENV['WEBHOOK_URL'],
    session_store: bot.session_store.class.name,
    timestamp: Time.now.to_i
  }

  File.write("/backup/config_#{Time.now.to_i}.json", config.to_json)
end
```

## Troubleshooting

### Common Issues

**Webhook not receiving updates:**
- Check SSL certificate validity
- Verify webhook URL is accessible
- Check firewall settings

**High memory usage:**
- Monitor for memory leaks
- Use connection pooling
- Implement proper garbage collection

**Rate limiting:**
- Implement exponential backoff
- Cache frequent requests
- Use webhooks instead of polling

**Database connection issues:**
- Check connection pool size
- Implement connection retry logic
- Monitor database performance

### Debug Mode

```ruby
if ENV['DEBUG'] == 'true'
  bot.logger.level = :debug
  bot.api.debug = true
end
```

### Log Analysis

```bash
# Search for errors
grep "ERROR" /var/log/telegem-bot.log

# Count requests per hour
grep "INFO.*request" /var/log/telegem-bot.log | cut -d' ' -f1 | uniq -c

# Monitor response times
grep "response_time" /var/log/telegem-bot.log | awk '{sum+=$2} END {print sum/NR}'
```

Production deployment requires careful consideration of security, performance, monitoring, and scalability to ensure reliable bot operation.</content>
<parameter name="filePath">/home/slick/telegem/docs/deployment.md
# Webhook Deployment Guide

## What Are Webhooks?

Webhooks are a way to receive updates from Telegram **in real-time**. Instead of constantly asking Telegram "do you have any messages for me?", webhooks let Telegram push messages directly to your server when they arrive.

### Polling vs Webhooks

**Polling (Old Way):**
- Your bot repeatedly asks Telegram for updates
- Slower response time (delays between checks)
- Higher resource usage
- Simpler to set up

**Webhooks (Modern Way):**
- Telegram sends updates to your server immediately
- Instant message delivery
- More efficient (only send when needed)
- Requires HTTPS and public server

## Quick Start for Beginners

### What You Need

1. A Telegram bot token (from @BotFather)
2. A server with a public domain (or use cloud platforms)
3. HTTPS enabled (let's encrypt is free!)
4. 5 minutes of setup time

### 60-Second Setup

```bash
# 1. Create your bot file (bot.rb)
echo 'require "telegem"

bot = Telegem.new(ENV["BOT_TOKEN"])

bot.command("start") do |ctx|
  ctx.reply("Hello from webhooks!")
end

server = bot.webhook(port: 3000)
server.run' > bot.rb

# 2. Deploy to Railway, Render, or Heroku (they handle HTTPS)
# 3. Set the webhook URL
ruby -e "
  require 'telegem'
  bot = Telegem.new(ENV['BOT_TOKEN'])
  bot.set_webhook(url: 'https://your-domain.com/YOUR_BOT_TOKEN')
"

# 4. Done! Your bot is now live
```

## How Webhooks Work

Here's what happens when a user sends a message:

1. **User sends message** → Telegram receives it
2. **Telegram sends HTTP POST** → Sends data to your webhook URL
3. **Your server processes** → Handles the message with your bot logic
4. **Send response** → Returns "OK" to confirm
5. **Telegram updates user** → Shows bot's reply

```
┌─────────────────────────────────────────────────────┐
│ User sends message to bot on Telegram               │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│ Telegram sends HTTP POST to: https://yourdomain.com │
│ with JSON: {message_id: 123, text: "hello", ...}   │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│ Your webhook server receives request                │
│ Processes message with your bot handlers           │
│ Sends reply back to Telegram                        │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│ Telegram delivers reply to user                     │
└─────────────────────────────────────────────────────┘
```

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

This section shows how to deploy your bot to real servers that stay running 24/7.

### Option 1: Free Cloud Hosting (Easiest for Beginners)

**Recommended platforms** (all free tier available):
- **Railway** - Simple, fast, free tier
- **Render** - Good free tier, auto-deploys from GitHub
- **Heroku** - Very popular, free tier removed but still a good option
- **Replit** - Great for learning, free tier

#### Railway Deployment (Easiest!)

1. **Create a simple bot file** (`bot.rb`):

```ruby
require 'telegem'

bot = Telegem.new(ENV['BOT_TOKEN'])

# Your bot handlers here
bot.command('start') do |ctx|
  ctx.reply("Hey #{ctx.from.first_name}!")
end

bot.command('help') do |ctx|
  ctx.reply("Commands: /start, /help")
end

# Start webhook server (Railway provides free HTTPS!)
server = bot.webhook(port: ENV['PORT'] || 3000)
server.run
```

2. **Create a Gemfile**:

```ruby
source 'https://rubygems.org'

gem 'telegem'
```

3. **Deploy to Railway**:

```bash
# Login to Railway
npm install -g railway  # or use web interface at railway.app

# Deploy
railway up

# Or: Push to GitHub and Railway auto-deploys
git push origin main
```

4. **Set webhook URL** (in your bot code or manually):

```bash
# Once deployed, get your Railway URL
# Then set webhook:
curl "https://api.telegram.org/botYOUR_BOT_TOKEN/setWebhook" \
  -d "url=https://your-railway-url/YOUR_BOT_TOKEN"
```

#### Render Deployment

1. **Push code to GitHub**

2. **Go to** https://dashboard.render.com

3. **Click "New" - "Web Service"**

4. **Connect your GitHub repository**

5. **Configure**:
   - Environment: Ruby
   - Build command: `bundle install`
   - Start command: `ruby bot.rb`
   - Add environment variable: `BOT_TOKEN` (your actual token)

6. **Deploy!** Render automatically sets HTTPS and your bot is live

### Option 2: Self-Hosted Server (Good if you have a server)

If you have your own server (VPS, dedicated host, etc.):

**Step 1: SSH into your server**

```bash
ssh user@your-server.com
```

**Step 2: Install Ruby**

```bash
# For Ubuntu/Debian
sudo apt update
sudo apt install ruby-full build-essential

# For CentOS/RHEL
sudo yum install ruby
```

**Step 3: Setup your bot directory**

```bash
mkdir -p ~/telegem-bot
cd ~/telegem-bot

# Create bot.rb with your code
# Create Gemfile with dependencies
```

**Step 4: Install SSL certificates using telegem-ssl**

```bash
# Point your domain to server first (DNS takes 5-15 mins)
gem install telegem

# Get free SSL certificate
telegem-ssl yourdomain.com your-email@example.com

# Answer the prompts - telegem-ssl handles everything!
```

**Step 5: Run your bot**

```bash
bundle install
ruby bot.rb

# Or run in background:
nohup ruby bot.rb > bot.log 2>&1 &

# Or use systemd (recommended):
sudo systemctl start telegem-bot
```

### Option 3: Docker Container (Most Professional)

Docker makes deployment consistent everywhere:

**Step 1: Create Dockerfile**

```dockerfile
FROM ruby:3.2-alpine

WORKDIR /app

# Install dependencies
RUN apk add --no-cache build-base

# Copy Gemfile
COPY Gemfile Gemfile.lock ./
RUN bundle install --deployment

# Copy your bot code
COPY . .

# Expose port for webhooks
EXPOSE 3000

# Run the bot
CMD ["ruby", "bot.rb"]
```

**Step 2: Create `.dockerignore`**

```
.git
.gitignore
*.log
node_modules
coverage
tmp
```

**Step 3: Create `Gemfile`**

```ruby
source 'https://rubygems.org'

gem 'telegem'
gem 'rack'
```

**Step 4: Create docker-compose.yml** (for local testing)

```yaml
version: '3'
services:
  bot:
    build: .
    ports:
      - "3000:3000"
    environment:
      - BOT_TOKEN=${BOT_TOKEN}
      - WEBHOOK_URL=${WEBHOOK_URL}
    restart: unless-stopped
```

**Step 5: Deploy**

```bash
# Build image
docker build -t telegem-bot .

# Run container
docker run -p 3000:3000 \
  -e BOT_TOKEN=your_token_here \
  telegem-bot

# Or with docker-compose
docker-compose up -d
```

### Deploying to Heroku

**Step 1: Create Procfile**

```
web: bundle exec ruby bot.rb
```

**Step 2: Create app.json** (optional, for easy deploy button)

```json
{
  "name": "Telegem Bot",
  "description": "A Telegram bot built with Telegem",
  "repository": "https://github.com/yourusername/your-bot-repo",
  "keywords": ["telegram", "bot", "ruby"],
  "env": {
    "BOT_TOKEN": {
      "description": "Your Telegram Bot API Token",
      "required": true
    }
  }
}
```

**Step 3: Deploy**

```bash
# Install Heroku CLI
npm install -g heroku

# Login
heroku login

# Create app
heroku create your-bot-name

# Set environment variables
heroku config:set BOT_TOKEN=your_token_here

# Deploy
git push heroku main
```

### Common Deployment Patterns

#### Pattern 1: GitHub + Railway Auto-Deploy

```
Code changes → Push to GitHub → Railway auto-redeploys → Bot updated
```

**Setup**:
1. Connect Railway to your GitHub repo
2. Every push to `main` auto-deploys!

#### Pattern 2: GitHub Actions + Custom Server

```
Code changes → Push → GitHub Actions runs tests → Deploys to server
```

**.github/workflows/deploy.yml**:

```yaml
name: Deploy Bot

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to server
        run: |
          ssh deploy@server "cd /app && git pull && bundle install && systemctl restart bot"
```

#### Pattern 3: Docker Registry + Production Server

```
Code → Docker image → Push to Docker Hub → Pull & run on server
```

```bash
# Build and push image
docker build -t yourusername/telegem-bot:latest .
docker push yourusername/telegem-bot:latest

# On server: pull and run
docker pull yourusername/telegem-bot:latest
docker run -d -e BOT_TOKEN=xxx yourusername/telegem-bot:latest
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

## SSL/TLS Configuration (HTTPS)

**Why HTTPS?** Telegram requires HTTPS for security. All data between your bot and Telegram must be encrypted.

Telegem supports **three ways** to get SSL certificates:

### 1. Cloud Platform SSL (Easiest for Beginners)

If you're using cloud platforms like **Heroku**, **Railway**, **Render**, or **Replit**, they automatically provide HTTPS for free. You don't need to do anything!

```ruby
# Cloud platforms handle SSL automatically
server = bot.webhook
server.run  # Just works!
```

**Platforms with automatic HTTPS:**
- Heroku
- Railway
- Render
- Replit
- Vercel
- Netlify

### 2. Automated SSL with telegem-ssl (Recommended for Self-Hosted)

If you're running your own server, use the built-in `telegem-ssl` tool to automatically get free SSL certificates from Let's Encrypt.

#### Installation & Usage

```bash
# Install gem with tools
gem install telegem

# Run the SSL setup tool
telegem-ssl yourdomain.com your-email@example.com
```

#### What telegem-ssl Does

The `telegem-ssl` script automates the entire SSL setup process:

1. **Checks if certbot is installed** (the Let's Encrypt client)
   - Installs it automatically if missing (supports apt, dnf, yum, brew)
   
2. **Gets a free SSL certificate** from Let's Encrypt using:
   - **Standalone mode** (easiest) - temporarily stops your bot to verify domain
   - **Webroot mode** (keeps running) - requires your web root path
   
3. **Creates configuration file** at `.telegem-ssl`
   - Stores certificate and key paths
   - Your bot automatically uses these certificates

4. **Shows auto-renewal instructions**
   - Certificates expire after 90 days
   - Cron job automatically renews them before expiration

#### Complete Example

```bash
# Step 1: Point your domain to your server's IP address
# (DNS setup - usually takes 5-15 minutes to propagate)

# Step 2: Run the SSL setup
telegem-ssl bot.example.com admin@example.com

# Output:
# → Checks for certbot (installs if needed)
# → Gets certificate from Let's Encrypt
# → Creates .telegem-ssl configuration file
# → Shows renewal instructions

# Step 3: Your bot code stays simple
require 'telegem'
bot = Telegem.new('YOUR_BOT_TOKEN')

# Bot automatically uses SSL from .telegem-ssl
server = bot.webhook(port: 443)
server.run

# Step 4 (optional): Set up auto-renewal
# Add this to crontab (crontab -e):
# 0 0 1 * * certbot renew --quiet && systemctl reload your-bot-service
```

#### telegem-ssl Configuration File

After running the tool, a `.telegem-ssl` file is created:

```yaml
# .telegem-ssl
domain: bot.example.com
cert_path: /etc/letsencrypt/live/bot.example.com/fullchain.pem
key_path: /etc/letsencrypt/live/bot.example.com/privkey.pem
```

Your bot automatically reads this file on startup!

#### Troubleshooting telegem-ssl

**"Connection refused" / "Failed to get certificate"**
- Make sure your domain points to your server's IP
- Wait for DNS to propagate (5-15 minutes)
- Check firewall allows port 80 and 443

**"Certbot not found" / "Package manager not detected"**
- Manually install certbot: https://certbot.eff.org/instructions
- Run `telegem-ssl` again

**Certificate renewal not working**
- Check that cron is running: `sudo service cron status`
- Run renewal manually: `sudo certbot renew --dry-run`
- View cron logs: `grep CRON /var/log/syslog`

### 3. Manual SSL Configuration

For advanced setups or custom certificates:

```ruby
require 'openssl'
require 'telegem'

# Load your existing certificates
ssl_context = OpenSSL::SSL::SSLContext.new
ssl_context.cert = OpenSSL::X509::Certificate.new(File.read('cert.pem'))
ssl_context.key = OpenSSL::PKey::RSA.new(File.read('key.pem'))

bot = Telegem.new('YOUR_BOT_TOKEN')
server = bot.webhook(
  port: 443,
  ssl_context: ssl_context
)
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
# lib/webhook/server.rb - V2.0.0 (CLOUD-READY)
require 'json'
require 'rack'

module Telegem
  module Webhook
    class Server
      attr_reader :bot, :port, :host, :logger, :running, :secret_token
      
      def initialize(bot, port: nil, host: '0.0.0.0', logger: nil, max_threads: 10, secret_token: nil)
        @bot = bot
        @port = port || ENV['PORT'] || 3000
        @host = host
        @logger = logger || Logger.new($stdout)
        @max_threads = max_threads
        @thread_pool = Concurrent::FixedThreadPool.new(max_threads)
        @secret_token = secret_token || generate_secret_token
        @server = nil
        @running = false
        @webhook_path = "/webhook"
      end
      
      # Production server with Puma
      def run
        return if @running
        
        @logger.info "🚀 Starting Telegem webhook server on #{@host}:#{@port}"
        @logger.info "📝 Set Telegram webhook to: #{webhook_url}"
        @logger.info "🔐 Secret token: #{@secret_token}"
        @logger.info "✅ Using Puma (production-ready)"
        @logger.info "☁️  Cloud-ready: #{cloud_platform}"
        
        @running = true
        
        app = build_rack_app
        start_puma_server(app)
        
        self
      end
      
      def stop
        return unless @running
        
        @logger.info "🛑 Stopping webhook server..."
        @running = false
        
        @server&.stop
        @thread_pool.shutdown
        @thread_pool.wait_for_termination(5)
        
        @logger.info "✅ Webhook server stopped"
      end
      
      alias_method :shutdown, :stop
      
      def running?
        @running
      end
      
      def webhook_url
        # For cloud platforms, use their URL
        if cloud_url = detect_cloud_url
          "#{cloud_url}#{@webhook_path}"
        elsif ENV['WEBHOOK_URL']
          ENV['WEBHOOK_URL']
        else
          # Local development
          "https://#{@host}:#{@port}#{@webhook_path}"
        end
      end
      
      def set_webhook(**options)
        params = {
          url: webhook_url,
          secret_token: @secret_token,
          drop_pending_updates: true
        }.merge(options)
        
        @bot.api.call!('setWebhook', params)
      end
      
      def delete_webhook
        @bot.api.call!('deleteWebhook', {})
      end
      
      # Quick setup helper
      def self.setup(bot, **options)
        server = new(bot, **options)
        server.run
        server.set_webhook
        server
      end
      
      private
      
      def build_rack_app
        Rack::Builder.new do
          use Rack::CommonLogger
          use Rack::ShowExceptions if ENV['RACK_ENV'] == 'development'
          
          # Health endpoint (required by Render/Railway/Heroku)
          map "/health" do
            run ->(env) { 
              [200, { 
                'Content-Type' => 'application/json',
                'Cache-Control' => 'no-cache'
              }, [{ 
                status: 'healthy',
                timestamp: Time.now.iso8601,
                service: 'telegem-webhook',
                version: Telegem::VERSION
              }.to_json]] 
            }
          end
          
          # Webhook endpoint
          map "/webhook" do
            run ->(env) do
              server = env['telegem.server']
              req = Rack::Request.new(env)
              
              if req.post?
                server.handle_rack_request(req)
              else
                [405, { 'Content-Type' => 'text/plain' }, ['Method Not Allowed']]
              end
            end
          end
          
          # Root landing page
          map "/" do
            run ->(env) do
              server = env['telegem.server']
              [200, { 'Content-Type' => 'text/html' }, [server.landing_page]]
            end
          end
        end
      end
      
      def start_puma_server(app)
        require 'puma'
        
        # Cloud platforms set PORT environment variable
        port = ENV['PORT'] || @port
        
        config = {
          Host: @host,
          Port: port,
          Threads: "0:#{@max_threads}",
          workers: ENV['WEB_CONCURRENCY']&.to_i || 1,
          daemonize: false,
          silent: false,
          environment: ENV['RACK_ENV'] || 'production',
          # Cloud platforms handle SSL termination
          ssl_bind: nil  # Let platform handle SSL
        }
        
        @server = Puma::Server.new(app)
        @server.add_tcp_listener(@host, port)
        
        @server.app = ->(env) do
          env['telegem.server'] = self
          app.call(env)
        end
        
        Thread.new do
          begin
            @server.run
          rescue => e
            @logger.error "❌ Puma server error: #{e.message}"
            @running = false
            raise
          end
        end
        
        sleep 1 until @server.running
      end
      
      def handle_rack_request(req)
        # Validate secret token from Telegram
        telegram_token = req.get_header('X-Telegram-Bot-Api-Secret-Token')
        
        if @secret_token && telegram_token != @secret_token
          @logger.warn "⚠️  Invalid secret token from #{req.ip}"
          return [403, { 'Content-Type' => 'text/plain' }, ['Forbidden']]
        end
        
        begin
          body = req.body.read
          update_data = JSON.parse(body)
          
          # Process in thread pool (not spawn new threads!)
          @thread_pool.post do
            begin
              @bot.process(update_data)
            rescue => e
              @logger.error "Error processing update: #{e.message}"
            end
          end
          
          [200, { 'Content-Type' => 'text/plain' }, ['OK']]
        rescue JSON::ParserError
          [400, { 'Content-Type' => 'text/plain' }, ['Bad Request']]
        rescue => e
          @logger.error "Webhook error: #{e.message}"
          [500, { 'Content-Type' => 'text/plain' }, ['Internal Server Error']]
        end
      end
      
      def landing_page
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>Telegem Webhook Server</title>
              <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
                       max-width: 800px; margin: 0 auto; padding: 20px; }
                .status { background: #4CAF50; color: white; padding: 5px 10px; border-radius: 3px; }
                code { background: #f5f5f5; padding: 2px 5px; border-radius: 3px; }
                a { color: #2196F3; text-decoration: none; }
              </style>
            </head>
            <body>
              <h1>🤖 Telegem Webhook Server</h1>
              <p><strong>Status:</strong> <span class="status">Running</span></p>
              <p><strong>Webhook URL:</strong> <code>#{webhook_url}</code></p>
              <p><strong>Health Check:</strong> <a href="/health">/health</a></p>
              <p><strong>Platform:</strong> #{cloud_platform}</p>
              <hr>
              <p>To set up your Telegram bot:</p>
              <pre><code>bot = Telegem.new('YOUR_TOKEN')
server = bot.webhook
server.run
server.set_webhook</code></pre>
            </body>
          </html>
        HTML
      end
      
      def generate_secret_token
        SecureRandom.hex(32)
      end
      
      def detect_cloud_url
        # Render
        if ENV['RENDER_EXTERNAL_URL']
          ENV['RENDER_EXTERNAL_URL']
        # Railway
        elsif ENV['RAILWAY_STATIC_URL']
          ENV['RAILWAY_STATIC_URL']
        # Heroku
        elsif ENV['HEROKU_APP_NAME']
          "https://#{ENV['HEROKU_APP_NAME']}.herokuapp.com"
        # Fly.io
        elsif ENV['FLY_APP_NAME']
          "https://#{ENV['FLY_APP_NAME']}.fly.dev"
        # Vercel (if using serverless)
        elsif ENV['VERCEL_URL']
          "https://#{ENV['VERCEL_URL']}"
        else
          nil
        end
      end
      
      def cloud_platform
        if ENV['RENDER'] then 'Render'
        elsif ENV['RAILWAY'] then 'Railway'
        elsif ENV['HEROKU_APP_NAME'] then 'Heroku'
        elsif ENV['FLY_APP_NAME'] then 'Fly.io'
        elsif ENV['VERCEL'] then 'Vercel'
        elsif ENV['DYNO'] then 'Heroku'
        else 'Local/Unknown'
        end
      end
    end
    
    # Rack Middleware for existing apps
    class Middleware
      def initialize(app, bot, secret_token: nil)
        @app = app
        @bot = bot
        @secret_token = secret_token || ENV['TELEGRAM_SECRET_TOKEN']
        @thread_pool = Concurrent::FixedThreadPool.new(10)
      end
      
      def call(env)
        req = Rack::Request.new(env)
        
        if req.post? && req.path == "/webhook"
          handle_webhook(req)
        else
          @app.call(env)
        end
      end
      
      private
      
      def handle_webhook(req)
        telegram_token = req.get_header('X-Telegram-Bot-Api-Secret-Token')
        
        if @secret_token && telegram_token != @secret_token
          return [403, { 'Content-Type' => 'text/plain' }, ['Forbidden']]
        end
        
        begin
          update_data = JSON.parse(req.body.read)
          
          @thread_pool.post do
            begin
              @bot.process(update_data)
            rescue => e
              @bot.logger&.error("Webhook error: #{e.message}")
            end
          end
          
          [200, { 'Content-Type' => 'text/plain' }, ['OK']]
        rescue JSON::ParserError
          [400, { 'Content-Type' => 'text/plain' }, ['Bad Request']]
        rescue => e
          @bot.logger&.error("Webhook error: #{e.message}")
          [500, { 'Content-Type' => 'text/plain' }, ['Internal Server Error']]
        end
      end
    end
  end
end
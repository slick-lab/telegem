# lib/webhook/server.rb - HTTPX VERSION
require 'json'
require 'webrick'

module Telegem
  module Webhook
    class Server
      attr_reader :bot, :port, :host, :logger, :server, :running

      def initialize(bot, port: nil, host: '0.0.0.0', logger: nil)
        @bot = bot
        @port = port
        @host = host
        @logger = logger || Logger.new($stdout)
        @server = nil
        @running = false
      end

      def run
        return if @running
        
        @logger.info "🚀 Starting Telegem webhook server on #{@host}:#{@port}"
        @logger.info "📝 Set your Telegram webhook to: #{webhook_url}"
        
        @running = true
        
        @server_thread = Thread.new do
          begin
            # Create WEBrick server
            @server = WEBrick::HTTPServer.new(
              Port: @port,
              BindAddress: @host,
              Logger: @logger,
              AccessLog: []
            )
            
            # Mount the webhook endpoint
            @server.mount_proc("/webhook/#{@bot.token}") do |req, res|
              handle_webhook_request(req, res)
            end
            
            # Mount health check
            @server.mount_proc('/health') do |req, res|
              res.status = 200
              res.content_type = 'text/plain'
              res.body = 'OK'
            end
            
            # Mount root
            @server.mount_proc('/') do |req, res|
              res.status = 200
              res.content_type = 'text/html'
              res.body = <<~HTML
                <html>
                  <head><title>Telegem Webhook Server</title></head>
                  <body>
                    <h1>Telegem Webhook Server</h1>
                    <p>Webhook URL: <code>#{webhook_url}</code></p>
                    <p>Status: <span style="color: green;">Running</span></p>
                    <p><a href="/health">Health Check</a></p>
                  </body>
                </html>
              HTML
            end
            
            # Handle shutdown signals
            ['INT', 'TERM'].each do |signal|
              Signal.trap(signal) { shutdown }
            end
            
            # Start the server
            @server.start
            
          rescue => e
            @logger.error "❌ Webhook server error: #{e.class}: #{e.message}"
            @logger.error e.backtrace.join("\n") if e.backtrace
            raise
          ensure
            @running = false
          end
        end
        
        self
      end

      def stop
        return unless @running
        
        @logger.info "🛑 Stopping webhook server..."
        @running = false
        
        # Stop WEBrick server
        @server&.shutdown
        
        # Wait for server thread
        @server_thread&.join(5)
        
        @logger.info "✅ Webhook server stopped"
      end

      alias_method :shutdown, :stop

      def running?
        @running
      end

      def webhook_url
        base_url = ENV['WEBHOOK_URL'] || "http://#{@host}:#{@port}"
        "#{base_url}/webhook/#{@bot.token}"
      end

      private

      def handle_webhook_request(req, res)
        # Only accept POST requests
        unless req.request_method == 'POST'
          res.status = 405
          res.content_type = 'text/plain'
          res.body = 'Method Not Allowed'
          return
        end

        begin
          # Parse the update
          body = req.body.read
          update_data = JSON.parse(body)
          
          # Process the update in a separate thread to keep response fast
          Thread.new do
            begin
              @bot.process(update_data)
            rescue => e
              @logger.error "Error processing update: #{e.message}"
            end
          end
          
          # Immediate response to Telegram
          res.status = 200
          res.content_type = 'text/plain'
          res.body = 'OK'
          
        rescue JSON::ParserError => e
          @logger.error "Invalid JSON in webhook request: #{e.message}"
          res.status = 400
          res.content_type = 'text/plain'
          res.body = 'Bad Request'
        rescue => e
          @logger.error "Error handling webhook: #{e.class}: #{e.message}"
          res.status = 500
          res.content_type = 'text/plain'
          res.body = 'Internal Server Error'
        end
      end
    end

    # Middleware for Rack apps (Rails, Sinatra, etc.)
    class Middleware
      def initialize(app, bot)
        @app = app
        @bot = bot
      end

      def call(env)
        req = Rack::Request.new(env)
        
        # Check if this is a webhook request
        if req.post? && req.path == "/webhook/#{@bot.token}"
          handle_webhook(req)
        else
          @app.call(env)
        end
      end

      private

      def handle_webhook(req)
        begin
          update_data = JSON.parse(req.body.read)
          
          # Process async in background
          Thread.new { @bot.process(update_data) }
          
          [200, { 'Content-Type' => 'text/plain' }, ['OK']]
        rescue JSON::ParserError
          [400, { 'Content-Type' => 'text/plain' }, ['Bad Request']]
        rescue => e
          @bot.logger.error("Webhook error: #{e.message}") if @bot.logger
          [500, { 'Content-Type' => 'text/plain' }, ['Internal Server Error']]
        end
      end
    end
  end
end
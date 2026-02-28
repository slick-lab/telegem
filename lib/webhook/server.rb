# lib/telegem/webhook/server.rb
require 'async/http/server'
require 'async/http/endpoint'
require 'openssl'
require 'yaml'
require 'json'
require 'securerandom'
require 'uri'

module Telegem
  module Webhook
    class Server
      attr_reader :bot, :port, :host, :logger, :secret_token, :running, :server, :ssl_mode

      def initialize(bot, port: nil, host: '0.0.0.0', secret_token: nil, logger: nil, ssl: nil)
        @bot = bot
        @port = port || ENV['PORT'] || 3000
        @host = host
        @secret_token = secret_token || ENV['WEBHOOK_SECRET_TOKEN'] || SecureRandom.hex(16)
        @logger = logger || Logger.new($stdout)
        @running = false
        @server = nil

        @ssl_mode, @ssl_context = determine_ssl_mode(ssl)
        log_configuration
        validate_ssl_setup
      end

      def determine_ssl_mode(ssl_options)
        return [:none, nil] if ssl_options == false

        if File.exist?('.telegem-ssl')
          config = YAML.load_file('.telegem-ssl')
          cert_path = config['cert_path']
          key_path = config['key_path']

          if cert_path && key_path && File.exist?(cert_path) && File.exist?(key_path)
            return [:cli, load_certificate_files(cert_path, key_path)]
          end
        end

        if ssl_options && ssl_options[:cert_path] && ssl_options[:key_path]
          return [:manual, load_certificate_files(ssl_options[:cert_path], ssl_options[:key_path])]
        end

        if ENV['TELEGEM_WEBHOOK_URL'] && URI(ENV['TELEGEM_WEBHOOK_URL']).scheme == 'https'
          return [:cloud, nil]
        end

        [:none, nil]
      end

      def load_certificate_files(cert_path, key_path)
        ctx = OpenSSL::SSL::SSLContext.new
        ctx.cert = OpenSSL::X509::Certificate.new(File.read(cert_path))
        ctx.key = OpenSSL::PKey::RSA.new(File.read(key_path))
        ctx
      rescue
        nil
      end

      def validate_ssl_setup
        case @ssl_mode
        when :cli, :manual
          raise "SSL certificate files not found or invalid" if @ssl_context.nil?
        when :cloud
          url = URI(ENV['TELEGEM_WEBHOOK_URL'])
          raise "TELEGEM_WEBHOOK_URL must be HTTPS" unless url.scheme == 'https'
        end
      end

      def log_configuration
        @logger.info("Webhook Server Configuration:")
        @logger.info("  Mode: #{@ssl_mode.to_s.upcase}")
        @logger.info("  Port: #{@port}")
        @logger.info("  Host: #{@host}")
        @logger.info("  Secret: #{@secret_token[0..8]}...")
      end

      def run
        return if @running
        @running = true

        case @ssl_mode
        when :cli, :manual
          endpoint = Async::HTTP::Endpoint.parse("https://#{@host}:#{@port}", ssl_context: @ssl_context)
          @logger.info("Starting HTTPS server with local certificates")
        when :cloud
          endpoint = Async::HTTP::Endpoint.parse("http://#{@host}:#{@port}")
          @logger.info("Starting HTTP server (cloud platform handles SSL)")
        else
          endpoint = Async::HTTP::Endpoint.parse("http://#{@host}:#{@port}")
          @logger.warn("Starting HTTP server (Telegram requires HTTPS)")
        end

        @server = Async::HTTP::Server.for(endpoint) do |request|
          handle_request(request)
        end

        Async do |task|
          @server.run
          task.sleep while @running
        end
      end

      def handle_request(request)
        case request.path
        when @secret_token, "/#{@secret_token}"
          handle_webhook_request(request)
        when '/health', '/healthz'
          health_endpoint(request)
        else
          [404, {}, ["Not Found"]]
        end
      end

      def handle_webhook_request(request)
        return [405, {}, ["Method Not Allowed"]] unless request.post?

        begin
          body = request.body.read
          update_data = JSON.parse(body)
           process_webhook_update(update_data) 
          [200, {}, ["OK"]]
        rescue
          [500, {}, ["Internal Server Error"]]
        end
      end

      def process_webhook_update(update_data)
        @bot.process(update_data)
      rescue => e
        @logger.error("Process error: #{e}")
      end

      def health_endpoint(request)
        [200, { 'Content-Type' => 'application/json' }, [{
          status: 'ok',
          mode: @ssl_mode.to_s,
          ssl: @ssl_mode != :none
        }.to_json]]
      end

      def stop
        return unless @running
        @running = false
        @server&.close
        @logger.info("Server stopped")
        @server = nil
      end

      def webhook_url
        case @ssl_mode
        when :cli, :manual
          "https://#{@host}:#{@port}#{@secret_token}"
        when :cloud
          cloud_url = ENV['TELEGEM_WEBHOOK_URL'].chomp('/')
          "#{cloud_url}#{@secret_token}"
        else
          "http://#{@host}:#{@port}#{@secret_token}"
        end
      end

      def set_webhook(**options)
        url = webhook_url
        params = { url: url }.merge(options)
        @bot.set_webhook(**params)
        @logger.info("Webhook set to: #{url}")
        url
      end

      def delete_webhook
        @bot.delete_webhook
        @logger.info("Webhook deleted")
      end

      def get_webhook_info
        @bot.get_webhook_info
      end

      def running?
        @running
      end
    end
  end
end
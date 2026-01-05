require 'async/http/server'
require 'async/http/endpoint'
require 'json'
require 'logger'

module Telegem
  module Webhook
    class Server
      attr_reader :bot, :port, :host, :logger, :secret_token, :running, :server

      def initialize(bot, port: nil, host: '0.0.0.0', secret_token: nil, logger: nil)
        @bot = bot
        @port = port || 3000
        @host = host
        @secret_token = secret_token
        @logger = logger || Logger.new($stdout)
        @running = false
        @server = nil
      end

      def run
        return if @running

        @running = true
        @logger.info "Starting webhook server on #{@host}:#{@port}"

        endpoint = Async::HTTP::Endpoint.parse("http://#{@host}:#{@port}")

        @server = Async::HTTP::Server.for(endpoint) do |request|
          case request.path
          when '/webhook'
            handle_webhook_request(request)
          when '/health'
            health_endpoint(request)
          else
            [404, {}, ["Not Found"]]
          end
        end

        Async do |task|
          @server.run
          task.sleep while @running
        end

        @logger.info "Webhook server running on http://#{@host}:#{@port}"
      end

      def stop
        return unless @running

        @running = false
        @server&.close
        @logger.info "Webhook server stopped"
        @server = nil
      end

      def webhook_url
        if @secret_token
          "https://#{@host}:#{@port}/webhook?secret_token=#{@secret_token}"
        else
          "https://#{@host}:#{@port}/webhook"
        end
      end

      def set_webhook(**options)
        url = webhook_url
        params = { url: url }
        params[:secret_token] = @secret_token if @secret_token
        params.merge!(options)

        @bot.set_webhook(**params)
        @logger.info "Webhook set to #{url}"
      end

      def delete_webhook
        @bot.delete_webhook
        @logger.info "Webhook deleted"
      end

      def get_webhook_info
        info = @bot.get_webhook_info
        @logger.info "Webhook info retrieved"
        info
      end

      private

      def handle_webhook_request(request)
        return [405, {}, ["Method Not Allowed"]] unless request.post?

        unless validate_secret_token(request)
          return [403, {}, ["Forbidden"]]
        end

        begin
          body = request.body.read
          update_data = JSON.parse(body)

          Async do |task|
            process_webhook_update(update_data)
          end

          [200, {}, ["OK"]]
        rescue JSON::ParserError
          [400, {}, ["Bad Request"]]
        rescue => e
          @logger.error "Webhook error: #{e.message}"
          [500, {}, ["Internal Server Error"]]
        end
      end

      def process_webhook_update(update_data)
        @bot.process(update_data)
      rescue => e
        @logger.error "Error processing update: #{e.message}"
      end

      def validate_secret_token(request)
        return true unless @secret_token

        token = request.query['secret_token'] || request.headers['x-telegram-bot-api-secret-token']
        token == @secret_token
      end

      def health_endpoint(request)
        [200, { 'Content-Type' => 'application/json' }, [{ status: 'ok' }.to_json]]
      end
    end
  end
end
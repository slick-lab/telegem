# lib/api/client.rb - CORRECTED VERSION
require 'httpx'
require 'concurrent'

module Telegem
  module API
    class Client
      BASE_URL = 'https://api.telegram.org'
      
      attr_reader :token, :logger

      def initialize(token, endpoint: nil, logger: nil)
        @token = token
        @logger = logger || Logger.new($stdout)
        
        # HTTPX client with persistent connections
        @http = HTTPX.plugin(:persistent)
                     .plugin(:retries, max_retries: 3)
                     .with(
                       timeout: { 
                         connect_timeout: 10, 
                         operation_timeout: 30,
                         keep_alive_timeout: 15
                       }
                     )
      end

      def call(method, params = {})
        # Start the async request
        promise = @http.post(
          "#{BASE_URL}/bot#{@token}/#{method}",
          json: params.compact
        )
        
        # Return a Future that users can wait on
        Concurrent::Future.execute do
          response = promise.wait  # Wait for HTTPX async request
          handle_response(response)
        end
      end

      def upload(method, params)
        promise = @http.post(
          "#{BASE_URL}/bot#{@token}/#{method}",
          form: params
        )
        
        Concurrent::Future.execute do
          response = promise.wait
          handle_response(response)
        end
      end

      def get_updates(offset: nil, timeout: 30, limit: 100)
        params = { timeout: timeout, limit: limit }
        params[:offset] = offset if offset
        call('getUpdates', params)
      end

      def close
        @http.close
      end

      private

      def handle_response(response)
        response.raise_for_status
        
        json = response.json
        unless json
          raise APIError, "Empty response from Telegram API"
        end
        
        if json['ok']
          json['result']
        else
          raise APIError.new(json['description'], json['error_code'])
        end
      end
    end

    class APIError < StandardError
      attr_reader :code
      def initialize(message, code = nil)
        super(message)
        @code = code
      end
    end
  end
end
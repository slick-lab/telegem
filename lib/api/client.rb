# lib/api/client.rb - CORRECTED VERSION
require 'httpx'

module Telegem
  module API
    class Client
      BASE_URL = 'https://api.telegram.org'
      
      attr_reader :token, :logger, :http

      def initialize(token, logger: nil, timeout: 30)
        @token = token
        @logger = logger || Logger.new($stdout)
        
        # HTTPX with persistent connections and proper async support
        @http = HTTPX.plugin(:persistent)
                     .plugin(:retries, max_retries: 3, retry_on: [Timeout::Error, HTTPX::Error])
                     .with(
                       timeout: { 
                         connect_timeout: 10,
                         write_timeout: 10,
                         read_timeout: timeout,
                         keep_alive_timeout: 15
                       },
                       headers: {
                         'Content-Type' => 'application/json',
                         'User-Agent' => "Telegem/#{Telegem::VERSION}"
                       }
                     )
      end

      # Main API call - returns HTTPX request (promise-like object)
      def call(method, params = {})
        url = "#{BASE_URL}/bot#{@token}/#{method}"
        
        @logger.debug("API Call: #{method}") if @logger
        
        # Return the async request object directly
        @http.post(url, json: params.compact)
             .then(&method(:handle_response))
             .on_error(&method(:handle_error))
      end

      # File upload method
      def upload(method, params)
        url = "#{BASE_URL}/bot#{@token}/#{method}"
        
        # Convert params to multipart form data
        form = params.map do |key, value|
          if file_object?(value)
            [key.to_s, HTTPX::FormData::File.new(value)]
          else
            [key.to_s, value.to_s]
          end
        end
        
        @http.post(url, form: form)
             .then(&method(:handle_response))
             .on_error(&method(:handle_error))
      end

      # Convenience method for getUpdates with proper async handling
      def get_updates(offset: nil, timeout: 30, limit: 100, allowed_updates: nil)
        params = { timeout: timeout, limit: limit }
        params[:offset] = offset if offset
        params[:allowed_updates] = allowed_updates if allowed_updates
        
        call('getUpdates', params)
      end

      # Close connections gracefully
      def close
        @http.close
      end

      # Synchronous version (for convenience in non-async contexts)
      def call!(method, params = {})
        request = call(method, params)
        request.wait  # Wait for completion
        handle_response(request)
      rescue => e
        handle_error(e, request)
      end

      private

      def handle_response(response)
        response.raise_for_status unless response.status == 200
        
        json = response.json
        unless json
          raise APIError, "Empty or invalid JSON response"
        end
        
        if json['ok']
          json['result']
        else
          raise APIError.new(json['description'], json['error_code'])
        end
      end

      def handle_error(error, request = nil)
        case error
        when HTTPX::TimeoutError
          @logger.error("Telegram API timeout: #{error.message}") if @logger
          raise NetworkError, "Request timeout: #{error.message}"
        when HTTPX::ConnectionError
          @logger.error("Connection error: #{error.message}") if @logger
          raise NetworkError, "Connection failed: #{error.message}"
        when HTTPX::HTTPError
          @logger.error("HTTP error #{error.response.status}: #{error.message}") if @logger
          raise APIError, "HTTP #{error.response.status}: #{error.message}"
        else
          @logger.error("Unexpected error: #{error.class}: #{error.message}") if @logger
          raise APIError, error.message
        end
      end

      def file_object?(obj)
        obj.is_a?(File) || obj.is_a?(StringIO) || obj.is_a?(Tempfile) ||
          (obj.is_a?(String) && File.exist?(obj))
      end
    end

    class APIError < StandardError
      attr_reader :code
      
      def initialize(message, code = nil)
        super(message)
        @code = code
      end
    end

    class NetworkError < APIError; end
  end
end
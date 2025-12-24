# lib/api/client.rb - MINIMAL WORKING VERSION
require 'httpx'
require 'json'

module Telegem
  module API
    class Client
      BASE_URL = 'https://api.telegram.org'
      
      attr_reader :token, :logger, :http

      def initialize(token, **options)
        @token = token
        @logger = options[:logger] || Logger.new($stdout)
        timeout = options[:timeout] || 30
        
        @http = HTTPX.with(
          timeout: timeout,
          headers: {
            'Content-Type' => 'application/json'
          }
        )
      end

      def call(method, params = {})
        url = "#{BASE_URL}/bot#{@token}/#{method}"
        @http.post(url, json: params.compact)
      end

      def call!(method, params = {})
        request = call(method, params)
        request.wait
        
        if request.error
          handle_error(request.error)
          return nil
        end
        
        handle_response(request.response)
      end

      def upload(method, params)
        url = "#{BASE_URL}/bot#{@token}/#{method}"
        form = params.map do |key, value|
          if file_object?(value)
            [key.to_s, HTTPX::FormData::File.new(value)]
          else
            [key.to_s, value.to_s]
          end
        end
        @http.post(url, form: form)
      end

      def get_updates(offset: nil, timeout: 30, limit: 100, allowed_updates: nil)
        params = { timeout: timeout, limit: limit }
        params[:offset] = offset if offset
        params[:allowed_updates] = allowed_updates if allowed_updates
        call('getUpdates', params)
      end

      def close
        @http.close
      end

      private

      def handle_response(response)
        return nil unless response
        
        if response.status != 200
          raise APIError, "HTTP #{response.status}"
        end
        
        json = response.json
        return nil unless json
        
        if json['ok']
          json['result']
        else
          raise APIError.new(json['description'], json['error_code'])
        end
      end

      def handle_error(error)
        @logger.error("API Error: #{error.message}") if @logger
        raise APIError, error.message
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
require 'httpx'
require 'json'

module Telegem
  module API
    class Client
      BASE_URL = 'https://api.telegram.org'
      
      attr_reader :token, :logger, :http

      def initialize(token, **options)
        @token = token
        @mutex = Mutex.new
        @logger = options[:logger] || Logger.new($stdout)
        timeout = options[:timeout] || 30
        
        @http = HTTPX.plugins(:callbacks).with(
          timeout: { 
            request_timeout: timeout,
            connect_timeout: 10,
            write_timeout: 10,
            read_timeout: timeout
          },
          headers: {
            'Content-Type' => 'application/json',
            'User-Agent' => "Telegem/#{Telegem::VERSION}"
          }
        )
      end
      def call(method, params = {})
        url = "#{BASE_URL}/bot#{@token}/#{method}"
        @logger.debug("API Call: #{method}") if @logger
        @http.post(url, json: params.compact).wait  
      end
        def call!(method, params = {}, &callback)
  url = "#{BASE_URL}/bot#{@token}/#{method}"
  
  # Ensure we have callbacks plugin
  http_client = @http.plugin(:callbacks) unless @http.plugins.include?(:callbacks)
  
  # Make the request
  request = http_client.post(url, json: params.compact)
  
  # Set up response handler
  request.on_response_completed do |response|
    begin
      if response.status == 200
        json = response.json
        if json && json['ok']
          # Success: callback with result
          callback.call(json['result'], nil) if callback
          @logger.debug("API Response: #{json}") if @logger
        else
          # API error (non-200 OK)
          error_msg = json ? json['description'] : "No JSON response"
          error_code = json['error_code'] if json
          callback.call(nil, APIError.new("API Error: #{error_msg}", error_code)) if callback
        end
      else
        # HTTP error
        callback.call(nil, NetworkError.new("HTTP #{response.status}")) if callback
      end
    rescue JSON::ParserError
      callback.call(nil, NetworkError.new("Invalid JSON response")) if callback
    rescue => e
      callback.call(nil, e) if callback
    end
  end
  
  # Set up network error handler
  request.on_request_error do |error|
    callback.call(nil, error) if callback
  end
  
  # Return the request (optional, for compatibility)
  request
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
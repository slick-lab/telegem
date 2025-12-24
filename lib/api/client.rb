# lib/api/client.rb - V2.0.0 (FIXED)
require 'httpx'
require 'json'

module Telegem
  module API
    class Client
      BASE_URL = 'https://api.telegram.org'
      
      attr_reader :token, :logger, :http, :connection_pool

      def initialize(token, **options)
        @token = token
        @logger = options[:logger] || Logger.new($stdout)
        timeout = options[:timeout] || 30
        pool_size = options[:pool_size] || 10
        
        @http = HTTPX.plugin(:persistent)
                     .with(
                       timeout: { 
                         connect_timeout: 10,
                         write_timeout: 10,
                         read_timeout: timeout,
                         keep_alive_timeout: 15
                       },
                       headers: {
                         'Content-Type' => 'application/json',
                         'User-Agent' => "Telegem/#{Telegem::VERSION} (Ruby #{RUBY_VERSION}; #{RUBY_PLATFORM})"
                       },
                       max_requests: pool_size
                     )
        
        if HTTPX.plugins.key?(:retries)
          @http = @http.plugin(:retries, max_retries: 3, retry_on: [500, 502, 503, 504])
        end
        
        ObjectSpace.define_finalizer(self, proc { close })
      end

      def call(method, params = {})
        url = "#{BASE_URL}/bot#{@token}/#{method}"
        
        @logger.debug("🚀 Async API: #{method}") if @logger
        
        @http.post(url, json: params.compact)
             .then(&method(:handle_response_async))
             .on_error(&method(:handle_error_async))
      end

      def call!(method, params = {}, timeout: nil)
        timeout ||= @http.options.timeout[:read_timeout]
        
        request = call(method, params)
        
        begin
          wait_result = request.wait(timeout)
          
          if request.error
            raise APIError, request.error.message
          elsif !wait_result
            raise NetworkError, "Request timeout after #{timeout}s"
          end
          
          request.instance_variable_get(:@result) || request.response
        rescue Timeout::Error
          raise NetworkError, "Request timeout after #{timeout}s"
        end
      end

      def upload(method, params)
        url = "#{BASE_URL}/bot#{@token}/#{method}"
        
        form = build_multipart_form(params)
        
        @logger.debug("📤 Async Upload: #{method}") if @logger
        
        @http.post(url, form: form)
             .then(&method(:handle_response_async))
             .on_error(&method(:handle_error_async))
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

      def handle_response_async(response)
        response.raise_for_status unless response.status == 200
        
        case response.status
        when 429
          retry_after = response.headers['retry-after']&.to_i || 1
          raise RateLimitError.new("Rate limited", retry_after)
        when 200
          begin
            json = response.json
          rescue JSON::ParserError => e
            raise APIError, "Invalid JSON: #{e.message}"
          end
          
          unless json
            raise APIError, "Empty response"
          end
          
          if json['ok']
            response.request.instance_variable_set(:@result, json['result'])
            json['result']
          else
            raise APIError.new(json['description'], json['error_code'])
          end
        else
          response.raise_for_status
        end
      end

      def handle_error_async(error)
        case error
        when HTTPX::TimeoutError
          @logger.error("⏰ Timeout: #{error.message}") if @logger
          raise NetworkError, "Timeout: #{error.message}"
        when HTTPX::ConnectionError
          @logger.error("🔌 Connection: #{error.message}") if @logger
          raise NetworkError, "Connection failed: #{error.message}"
        when HTTPX::HTTPError
          @logger.error("🌐 HTTP #{error.response.status}: #{error.message}") if @logger
          raise APIError, "HTTP #{error.response.status}: #{error.message}"
        when RateLimitError
          @logger.error("🚦 Rate limit: retry after #{error.retry_after}s") if @logger
          raise error
        else
          @logger.error("💥 Unexpected: #{error.class}: #{error.message}") if @logger
          raise APIError, error.message
        end
      end

      def build_multipart_form(params)
        params.map do |key, value|
          if file_object?(value)
            [key.to_s, HTTPX::FormData::File.new(value)]
          else
            [key.to_s, value.to_s]
          end
        end
      end

      def file_object?(obj)
        case obj
        when File, StringIO, Tempfile
          true
        when Pathname
          obj.exist? && obj.readable?
        when String
          if obj.start_with?('http://', 'https://', 'ftp://')
            false
          else
            File.exist?(obj) && File.readable?(obj)
          end
        else
          false
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

    class NetworkError < APIError; end
    
    class RateLimitError < APIError
      attr_reader :retry_after
      
      def initialize(message, retry_after = 1)
        super(message)
        @retry_after = retry_after
      end
    end
  end
end
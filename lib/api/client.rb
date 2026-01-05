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
        
        @http = HTTPX.with(
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
        def call!(method, params, &callback)
          url = "#{BASE_URL}/bot#{@token}/#{method}" 

          @http.post(url, json: params)
            .on_complete do |response|
              if response.status == 200
                json = response.json
                if json && json['ok']
                  callback.call(json['result']) if callback
                  @logger.debug("API Response: #{json}") if @logger
                else
                  error_msg = json ? json['description'] : "No JSON response"
                  error_code = json['error_code'] if json
                  raise APIError.new("API Error: #{error_msg}", error_code)
                end
              else
                raise NetworkError.new("HTTP #{response.status}")
              end
            rescue JSON::ParserError
              raise NetworkError.new("Invalid JSON response")
            rescue => e
              raise e
            end
            .on_error { |error| callback.call(nil, error) if callback }
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
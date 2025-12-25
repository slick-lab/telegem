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
        @http.post(url, json: params.compact)
      end

      def call!(method, params = {})
        url = "#{BASE_URL}/bot#{@token}/#{method}"
        
        @logger.debug("API Call (sync): #{method}") if @logger
        
        begin
          response = @http.post(url, json: params.compact)
          
          if response.respond_to?(:status) && response.status == 200
            json = response.json
            return json['result'] if json && json['ok']
          end
          
          @logger.error("API Error: HTTP #{response.status}") if response.respond_to?(:status) && @logger
        rescue => e
          @logger.error("Exception: #{e.message}") if @logger
        end
        
        nil
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
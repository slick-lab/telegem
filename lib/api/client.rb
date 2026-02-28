require 'async/http'
require 'json'

module Telegem
  module API
    class Client
      BASE_URL = 'https://api.telegram.org'
      
      attr_reader :token, :logger

      def initialize(token, **options)
        @token = token
        @logger = options[:logger] || Logger.new($stdout)
        @timeout = options[:timeout] || 30
        
        @endpoint = Async::HTTP::Endpoint.parse(BASE_URL)
        @client = Async::HTTP::Client.new(@endpoint)
      end
      
      def call(method, params = {})
          make_request(method, params)
      end
      
      def call!(method, params = {}, &callback)
        return unless callback
          begin
            result = make_request(method, params)
            callback.call(result, nil)
          rescue => error
            callback.call(nil, error)
          end
      end
      def upload(method, params)
          url = "/bot#{@token}/#{method}"
          
          body = Async::HTTP::Body::Multipart.new
          
          params.each do |key, value|
            if file_object?(value)
              body.add(key.to_s, value, filename: File.basename(value))
            else
              body.add(key.to_s, value.to_s)
            end
          end
          
          response = @client.post(url, {}, body)
          handle_response(response)

      end
      
      def download(file_id, destination_path = nil)
          file_info = call('getFile', file_id: file_id)
          return nil unless file_info && file_info['file_path']
          
          file_path = file_info['file_path']
          download_url = "/file/bot#{@token}/#{file_path}"
          
          response = @client.get(download_url)
          
          if response.status == 200
            content = response.read
            if destination_path
              File.binwrite(destination_path, content)
              destination_path
            else
              content
            end
          else
            raise NetworkError.new("Download failed: HTTP #{response.status}")
          end
      end
      
      def get_updates(offset: nil, timeout: 30, limit: 100, allowed_updates: nil)
        params = { timeout: timeout, limit: limit }
        params[:offset] = offset if offset
        params[:allowed_updates] = allowed_updates if allowed_updates
        call('getUpdates', params)
      end
      
      def close
        @client.close
      end
      
      private
      
      def make_request(method, params)
        url = "/bot#{@token}/#{method}"
        @logger.debug("Api call #{method}") if @logger
        
        response = @client.post(
          url,
          { 'content-type' => 'application/json' },
          JSON.dump(params.compact)
        )
        
        handle_response(response)
      end
      
      def handle_response(response)
        json = JSON.parse(response.read)
        
        if json && json['ok']
          json['result']
        else
          raise APIError.new(json ? json['description'] : "Api Error")
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
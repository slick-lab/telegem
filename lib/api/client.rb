require "async/http"
require "json"
require "logger"
require "securerandom"
require "stringio"
require "tempfile"

module Telegem
  module API
    class MultipartForm
      CRLF = "\r\n"

      attr_reader :content_type

      def initialize
        @boundary = "----telegem#{SecureRandom.hex(16)}"
        @content_type = "multipart/form-data; boundary=#{@boundary}"
        @parts = []
      end

      def add(name, value)
        if file?(value)
          append_file(name, value)
        else
          append_field(name, value.to_s)
        end
      end

      def body
        String.new.tap do |buffer|
          @parts.each do |part|
            buffer << "--#{@boundary}#{CRLF}"
            buffer << part
            buffer << CRLF
          end

          buffer << "--#{@boundary}--#{CRLF}"
        end
      end

      private

      def append_field(name, value)
        @parts << <<~PART.gsub("\n", CRLF)
          Content-Disposition: form-data; name="#{name}"

          #{value}
        PART
      end

      def append_file(name, value)
        io =
          case value
          when String
            File.open(value, "rb")
          else
            value
          end

        filename =
          if io.respond_to?(:path) && io.path
            File.basename(io.path)
          else
            "upload.bin"
          end

        mime =
          case File.extname(filename).downcase
          when ".jpg", ".jpeg"
            "image/jpeg"
          when ".png"
            "image/png"
          when ".gif"
            "image/gif"
          when ".webp"
            "image/webp"
          when ".mp4"
            "video/mp4"
          when ".mp3"
            "audio/mpeg"
          when ".ogg"
            "audio/ogg"
          when ".pdf"
            "application/pdf"
          else
            "application/octet-stream"
          end

        @parts << String.new.tap do |part|
          part << %(Content-Disposition: form-data; name="#{name}"; filename="#{filename}") << CRLF
          part << "Content-Type: #{mime}" << CRLF
          part << CRLF
          part << io.read
        end

        io.close if value.is_a?(String)
      end

      def file?(obj)
        obj.is_a?(File) ||
          obj.is_a?(Tempfile) ||
          obj.is_a?(StringIO) ||
          (obj.is_a?(String) && File.file?(obj))
      end
    end

    class Client
      BASE_URL = "https://api.telegram.org"

      attr_reader :token, :logger

      def initialize(token, **options)
        @token = token
        @logger = options[:logger] || Logger.new($stdout)
        @timeout = options[:timeout] || 30
        @retries = options[:retries] || 3
        @retry_delay = options[:retry_delay] || 1

        @endpoint = Async::HTTP::Endpoint.parse(BASE_URL, timeout: @timeout)
        @client = Async::HTTP::Client.new(@endpoint)
      end

      def call(method, params = {})
        with_retry do
          make_request(method, params)
        end
      end

      def call!(method, params = {}, &callback)
        return unless callback

        begin
          result = call(method, params)
          callback.call(result, nil)
        rescue => error
          callback.call(nil, error)
        end
      end

      def upload(method, params)
        with_retry do
          url = "/bot#{@token}/#{method}"

          form = MultipartForm.new

          params.each do |key, value|
            form.add(key.to_s, value)
          end

          body = form.body

          response = @client.post(
            url,
            {
              "content-type" => form.content_type,
              "content-length" => body.bytesize.to_s
            },
            body
          )

          handle_response(response)
        end
      end

      def download(file_id, destination_path = nil)
        with_retry do
          file_info = call("getFile", file_id: file_id)
          return nil unless file_info && file_info["file_path"]

          file_path = file_info["file_path"]
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
      end

      def get_updates(offset: nil, timeout: 30, limit: 100, allowed_updates: nil)
        params = {
          timeout: timeout,
          limit: limit
        }

        params[:offset] = offset if offset
        params[:allowed_updates] = allowed_updates if allowed_updates

        call("getUpdates", params)
      end

      def close
        @client.close
      end

      private

      def with_retry
        retries = 0

        begin
          yield
        rescue NetworkError, Async::TimeoutError => e
          retries += 1

          if retries <= @retries
            @logger.warn("API request failed: #{e.message}. Retry #{retries}/#{@retries}") if @logger
            sleep(@retry_delay * retries)
            retry
          else
            raise
          end
        rescue APIError
          raise
        end
      end

      def make_request(method, params)
        url = "/bot#{@token}/#{method}"

        @logger.debug("API call #{method}") if @logger

        response = @client.post(
          url,
          {
            "content-type" => "application/json"
          },
          JSON.dump(params.compact)
        )

        handle_response(response)
      end

      def handle_response(response)
        json = JSON.parse(response.read)

        if json["ok"]
          json["result"]
        else
          error_msg = json["description"] || "HTTP #{response.status}"
          raise APIError.new(error_msg, response.status)
        end
      end

      def file_object?(obj)
        obj.is_a?(File) ||
          obj.is_a?(StringIO) ||
          obj.is_a?(Tempfile) ||
          (obj.is_a?(String) && File.file?(obj))
      end
    end

    class APIError < StandardError
      attr_reader :code

      def initialize(message, code = nil)
        super(message)
        @code = code
      end
    end

    class NetworkError < APIError
    end
  end
end
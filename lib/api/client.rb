      module Telegem
        module API
          class Client
            BASE_URL = 'https://api.telegram.org'

            attr_reader :token, :logger

            def initialize(token, endpoint: nil, logger: nil)
              @token = token
              @logger = logger || Logger.new($stdout)
              @endpoint = endpoint || Async::HTTP::Endpoint.parse("#{BASE_URL}/bot#{token}")
              @client = nil
              @semaphore = Async::Semaphore.new(30)
            end

            def call(method, params = {})
              Async do |task|
                @semaphore.async do
                  make_request(method, clean_params(params))
                end
              end
            end

            def upload(method, params)
              Async do |task|
                @semaphore.async do
                  make_multipart_request(method, params)
                end
              end
            end

            def get_updates(offset: nil, timeout: 30, limit: 100)
              params = { timeout: timeout, limit: limit }
              params[:offset] = offset if offset
              call('getUpdates', params)
            end

            def close
              @client&.close
            end

            private

            def make_request(method, params)
              with_client do |client|
                headers = { 'content-type' => 'application/json' }
                body = params.to_json

                response = client.post("/bot#{@token}/#{method}", headers, body)
                handle_response(response)
              end
            end

            def make_multipart_request(method, params)
              with_client do |client|
                form = build_multipart(params)
                headers = form.headers

                response = client.post("/bot#{@token}/#{method}", headers, form.body)
                handle_response(response)
              end
            end

            def with_client(&block)
              @client ||= Async::HTTP::Client.new(@endpoint)
              yield @client
            end

            def clean_params(params)
              params.reject { |_, v| v.nil? }
            end

            def build_multipart(params)
              # Build multipart form data for file uploads
              boundary = SecureRandom.hex(16)
              parts = []

              params.each do |key, value|
                if file?(value)
                  parts << part_from_file(key, value, boundary)
                else
                  parts << part_from_field(key, value, boundary)
                end
              end

              parts << "--#{boundary}--\r\n"

              body = parts.join
              headers = {
                'content-type' => "multipart/form-data; boundary=#{boundary}",
                'content-length' => body.bytesize.to_s
              }

              OpenStruct.new(headers: headers, body: body)
            end

            def file?(value)
              value.is_a?(File) || 
              value.is_a?(StringIO) || 
              (value.is_a?(String) && File.exist?(value))
            end

            def part_from_file(key, file, boundary)
              filename = File.basename(file.path) if file.respond_to?(:path)
              filename ||= "file"

              mime_type = MIME::Types.type_for(filename).first || 'application/octet-stream'

              content = if file.is_a?(String)
                          File.read(file)
                        else
                          file.read
                        end

              <<~PART
                --#{boundary}\r
                Content-Disposition: form-data; name="#{key}"; filename="#{filename}"\r
                Content-Type: #{mime_type}\r
                \r
                #{content}\r
              PART
            end

            def part_from_field(key, value, boundary)
              <<~PART
                --#{boundary}\r
                Content-Disposition: form-data; name="#{key}"\r
                \r
                #{value}\r
              PART
            end

            def handle_response(response)
              body = response.read
              json = JSON.parse(body)

              if json['ok']
                json['result']
              else
                raise APIError.new(json['description'], json['error_code'])
              end
            rescue JSON::ParserError
              raise APIError, "Invalid JSON response: #{body[0..100]}"
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
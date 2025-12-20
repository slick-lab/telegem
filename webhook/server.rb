    module Telegem
      module Webhook
        class Server
          attr_reader :bot, :endpoint, :server, :logger

          def initialize(bot, endpoint: nil, logger: nil)
            @bot = bot
            @endpoint = endpoint || Async::HTTP::Endpoint.parse("http://0.0.0.0:3000")
            @logger = logger || Logger.new($stdout)
            @server = nil
            @running = false
          end

          def run
            Async do |task|
              @server = Async::HTTP::Server.new(app, @endpoint)
              @running = true

              @logger.info "Starting webhook server on #{@endpoint}"
              @logger.info "Set your Telegram webhook to: #{webhook_url}"

              @server.run
            rescue => e
              @logger.error "Webhook server error: #{e.message}"
              raise
            ensure
              @running = false
            end
          end

          def stop
            Async do
              @server&.close
              @running = false
              @logger.info "Webhook server stopped"
            end
          end

          def running?
            @running
          end

          def webhook_url
            "#{@endpoint.url}/webhook/#{@bot.token}"
          end

          def app
            proc do |req|
              handle_request(req)
            end
          end

          def process_webhook_request(req)
            Async do 
              body = req.body.read
              data = JSON.parse(body)
              await @bot.process(data)
              [200, {}, ["OK"]]
            rescue JSON::ParserError => e
              @logger.error "Invalid JSON in webhook request: #{e.message}"
              [400, {}, ["Bad Request"]]
            rescue => e
              @logger.error "Error processing webhook request: #{e.message}"
              [500, {}, ["Internal Server Error"]] 
            end
          end

          def handle_request(req)
            Async do 
              case req.path
              when "/webhook/#{@bot.token}"
                process_webhook_request(req)
              when "/health"
                [200, {}, ["OK"]]
              else 
                [404, {}, ["Not Found"]]
              end
            end
          end

          def call(req)
            handle_request(req)
          end
        end
      end
    end
module Telegem
  VERSION = '0.1.0'.freeze

  # Define module structure
  module API; end
  module Core; end
  module Session; end
  module Markup; end
  module Webhook; end
  module Types; end

  # Shortcut for creating a new bot
  def self.new(token, **options)
    require_relative 'lib/core/bot'
    Core::Bot.new(token, **options)
  end

  # Configure global settings
  def self.configure(&block)
    yield(config) if block_given?
    config
  end

  def self.config
    @config ||= Configuration.new
  end

  class Configuration
    attr_accessor :logger, :default_adapter, :default_concurrency,
                  :default_session_store, :default_webhook_port

    def initialize
      @logger = Logger.new($stdout)
      @default_adapter = :async_http
      @default_concurrency = 10
      @default_session_store = :memory
      @default_webhook_port = 3000
    end
  end

  # Error base class
  class Error < StandardError; end
end

# Load all components
require_relative 'lib/api/client'
require_relative 'lib/api/types'
require_relative 'lib/core/bot'
require_relative 'lib/core/context'
require_relative 'lib/core/composer'
require_relative 'lib/core/scene'
require_relative 'lib/session/middleware'
require_relative 'lib/session/memory_store'
require_relative 'lib/markup/keyboard'
require_relative 'webhook/server'
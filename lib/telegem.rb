# lib/telegem.rb - MAIN ENTRY POINT
require 'logger'
require 'json'

module Telegem
  VERSION = "2.0.1".freeze
end

# Load core components
require_relative 'api/client'
require_relative 'api/types'
require_relative 'core/bot'
require_relative 'core/context'
require_relative 'core/composer'
require_relative 'core/scene'
require_relative 'session/middleware'
require_relative 'session/memory_store'
require_relative 'markup/keyboard'
# Webhook is loaded lazily when needed

module Telegem
  # Main entry point: Telegem.new(token)
  def self.new(token, **options)
    Core::Bot.new(token, **options)
  end
  
  # Shortcut for creating keyboards
  def self.keyboard(&block)
    Markup.keyboard(&block)
  end
  
  def self.inline(&block)
    Markup.inline(&block)
  end
  
  # Remove keyboard markup
  def self.remove_keyboard(**options)
    Markup.remove(**options)
  end
  
  # Force reply markup
  def self.force_reply(**options)
    Markup.force_reply(**options)
  end
  
  # Current version
  def self.version
    VERSION
  end
  
  # Quick webhook setup
  def self.webhook(bot, **options)
    require_relative 'webhook/server'
    Webhook::Server.setup(bot, **options)
  end
  
  # Framework information
  def self.info
    <<~INFO
      🤖 Telegem #{VERSION}
      Modern Telegram Bot Framework for Ruby
      
      Features:
      • Async HTTPX-based API client
      • Scene system for multi-step conversations  
      • Express.js-style middleware
      • Clean Telegraf.js-inspired DSL
      • Webhook and polling support
      • Built-in session management
      • Fluent keyboard DSL
      • Cloud-ready webhook server
      
      Website: https://gitlab.com/ruby-telegem/telegem
    INFO
  end
end

# Optional global shortcut (enabled by env var)
if ENV['TELEGEM_GLOBAL'] == 'true'
  def Telegem(token, **options)
    Telegem.new(token, **options)
  end
end
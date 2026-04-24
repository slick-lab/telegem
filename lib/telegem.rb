
require 'logger'
require 'json'

module Telegem
  VERSION = "3.3.1".freeze
end

#
require_relative 'api/client'
require_relative 'api/types'
require_relative 'core/bot'
require_relative 'core/context'
require_relative 'core/composer'
require_relative 'core/scene'
require_relative 'session/middleware'
require_relative 'session/memory_store'
require_relative 'markup/keyboard'
require_relative 'markup/inline'

require_relative 'plugins/file_extract'
require_relative 'session/scene_middleware'

module Telegem

  def self.new(token, **options)
    Core::Bot.new(token, **options)
  end
  

  def self.keyboard(&block)
    Markup.keyboard(&block)
  end
  
  def self.inline(&block)
    Markup.inline(&block)
  end
  
  def self.remove_keyboard(**options)
    Markup.remove(**options)
  end
  
  def self.force_reply(**options)
    Markup.force_reply(**options)
  end
  
  def self.version
    VERSION
  end

  def self.webhook(bot, **options)
    require_relative 'webhook/server'
    Webhook::Server.setup(bot, **options)
  end
  
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


if ENV['TELEGEM_GLOBAL'] == 'true'
  def Telegem(token, **options)
    ::Telegem.new(token, **options)
  end
end

require 'json'
require 'telegem'
require 'sqlite3'
require 'fileutils'


require_relative './handlers/start'
require_relative './handlers/add_1_'
require_relative './handlers/premium'
require_relative './handlers/add_2_'
require_relative './handlers/sponsor'
require_relative './handlers/watch'
require_relative './handlers/report'
require_relative './handlers/search'
  
bot_token = ENV['BOT_TOKEN'] 

  bot = Telegem.new(ENV['BOT_TOKEN'])
 puts "token is #{bot_token[0..10]}"
 # In your code:
@db = SQLite3::Database.new "movieflix.db"

puts "started sqlite"

StartHandler.new(bot, db)
SearchHandler.new(bot, db)
WatchHandler.new(bot, db)
HelpHandler.new(bot)
PremiumHandler.new(bot)
SponsorHandler.new(bot)
AddHandler.new(bot, db)
AddHears.new(bot, db)

  port = (ENV['PORT'] || 3000).to_i
  puts "  📍 Using port: #{port}"
  puts "  🌐 Bind host: 0.0.0.0"
  
  # Start polling
  bot.start_polling
  puts " started polling"
  
  # Minimal health check server
  Thread.new do
    require 'socket'
    server = TCPServer.new('0.0.0.0', ENV['PORT'] || 10000)
    puts "✅ Health check server listening on port #{ENV['PORT'] || 10000}"
    
    loop do
      client = server.accept
      request = client.gets
      
      # Simple response for any request
      client.puts "HTTP/1.1 200 OK\r\n"
      client.puts "Content-Type: text/plain\r\n"
      client.puts "\r\n"
      client.puts "Telegram Bot is running"
      client.close
    end
  end 
   
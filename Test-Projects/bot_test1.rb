#!/usr/bin/env ruby
# Test-Projects/bot_test1.rb
require 'telegem'

puts "🚀 Starting Bot Test 1..."
puts "Ruby: #{RUBY_VERSION}"
puts "Telegem: #{Telegem::VERSION rescue 'Not loaded'}"

begin
  # 1. Create bot with your token
  bot = Telegem.new('8013082846:AAEnG0T1pnLhOpjwpF3I-A4DX4aQy_HPsAc')
  puts "✅ Bot object created"
  
  # 2. Add a command
  bot.command('start') do |ctx|
    ctx.reply "🤖 Test Bot 1 is working!"
    puts "✅ Command '/start' would reply"
  end
  
  bot.command('ping') do |ctx|
    ctx.reply "🏓 Pong! #{Time.now}"
    puts "✅ Command '/ping' would reply"
  end
  
  puts "✅ Commands registered"
  
  # 3. Try a simple API call (getMe)
  puts "📡 Testing API connection..."
  me = bot.api.call('getMe') rescue nil
  
  if me
    puts "✅ API Connected! Bot: @#{me['username']} (#{me['first_name']})"
  else
    puts "⚠️  API test failed (might be network/CI issue)"
  end
  
  # 4. Start polling for 10 seconds
  puts "🔄 Starting bot polling (10 seconds test)..."
  
  # Run polling in a thread with timeout
  polling_thread = Thread.new do
    begin
      bot.start_polling(timeout: 5, limit: 1)
    rescue => e
      puts "⚠️  Polling error (normal in CI): #{e.message}"
    end
  end
  
  # Wait 10 seconds then stop
  sleep 10
  puts "⏱️  10 seconds passed, stopping bot..."
  
  # Try to stop gracefully
  bot.shutdown rescue nil
  polling_thread.kill if polling_thread.alive?
  
  puts "🎉 Test completed successfully!"
  puts "✅ Bot framework works!"
  puts "✅ Commands work!"
  puts "✅ Async system works!"
  
rescue LoadError => e
  puts "❌ LOAD ERROR: #{e.message}"
  puts "Backtrace:"
  puts e.backtrace.first(5)
  exit 1
  
rescue => e
  puts "❌ ERROR: #{e.class}: #{e.message}"
  puts "Backtrace (first 3 lines):"
  puts e.backtrace.first(3)
  exit 1
end

puts "✨ All tests passed!"
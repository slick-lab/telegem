require 'telegem'
require 'dotenv/load'

bot = Telegem.new(ENV['BOT_TOKEN'])

bot.command('start') do |ctx|
  ctx.reply("Welcome! Use /help for commands.")

  response = ctx.reply("Processing your request...")

  if response && response.status == 200
    data = response.json
    if data && data['ok']
      ctx.session[:start_msg_id] = data['result']['message_id']
    end
  end
end

bot.command('help') do |ctx|
  help_text = <<~HELP
    Available commands:
    /start - Start the bot
    /help - This help message
    /edit - Edit the start message
    /error - Test error handling
    /photo - Send a photo
  HELP

  ctx.reply(help_text)
end

bot.command('edit') do |ctx|
  if ctx.session[:start_msg_id]
    edit_response = ctx.edit_message_text(
      "✅ Updated at #{Time.now.strftime('%H:%M:%S')}",
      message_id: ctx.session[:start_msg_id]
    )

    if edit_response && edit_response.status == 200
      ctx.reply("Message edited successfully!")
    else
      status = edit_response ? edit_response.status : 'no response'
      ctx.reply("Edit failed (status: #{status})")
    end
  else
    ctx.reply("Send /start first to create a message to edit.")
  end
end

bot.command('photo') do |ctx|
  photo_response = ctx.photo(
    "https://picsum.photos/400/300",
    caption: "Random image - #{Time.now.strftime('%H:%M:%S')}"
  )

  if photo_response && photo_response.status == 200
    ctx.reply("Photo sent successfully!")
  else
    ctx.reply("Failed to send photo.")
  end
end

bot.command('error') do |ctx|
  begin
    invalid_response = ctx.reply(nil)

    if invalid_response && invalid_response.status != 200
      error_data = invalid_response.json rescue nil
      error_msg = error_data ? error_data['description'] : "Unknown error"
      ctx.reply("API Error: #{error_msg}")
    end
  rescue => e
    ctx.reply("Ruby Error: #{e.message}")
  end
end

bot.on(:callback_query) do |ctx|
  ctx.answer_callback_query(text: "Button clicked: #{ctx.data}")

  if ctx.data == 'test'
    ctx.edit_message_text("You clicked the test button!")
  end
end

if ENV['RACK_ENV'] == 'production'
  server = bot.webhook(port: ENV['PORT'] || 3000)
  server.run
  server.set_webhook
else
  bot.start_polling(timeout: 30, limit: 100)
end
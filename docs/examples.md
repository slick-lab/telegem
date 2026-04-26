# Examples

Practical examples showing how to build various types of bots with Telegem.

## Basic Echo Bot

```ruby
require 'telegem'

bot = Telegem.new(token: 'YOUR_BOT_TOKEN')

bot.hears(/.*/) do |ctx|
  ctx.reply(ctx.text)
end

bot.start_polling
```

## Command Bot

```ruby
require 'telegem'

bot = Telegem.new(token: 'YOUR_BOT_TOKEN')

bot.command('start') do |ctx|
  ctx.reply("Hello! I'm a command bot.")
end

bot.command('help') do |ctx|
  help_text = <<~HELP
  Available commands:
  /start - Start the bot
  /help - Show this help
  /echo <text> - Echo back your text
  /time - Show current time
  HELP

  ctx.reply(help_text)
end

bot.command('echo') do |ctx|
  text = ctx.command_args
  if text.empty?
    ctx.reply("Usage: /echo <text>")
  else
    ctx.reply(text)
  end
end

bot.command('time') do |ctx|
  ctx.reply("Current time: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}")
end

bot.start_polling
```

## Inline Keyboard Bot

```ruby
require 'telegem'

bot = Telegem.new(token: 'YOUR_BOT_TOKEN')

bot.command('menu') do |ctx|
  keyboard = Telegem.inline_keyboard do |kb|
    kb.row do
      kb.button('Option 1', callback_data: 'opt1')
      kb.button('Option 2', callback_data: 'opt2')
    end
    kb.row do
      kb.button('Help', callback_data: 'help')
    end
  end

  ctx.reply('Choose an option:', keyboard: keyboard)
end

bot.callback_query do |ctx|
  case ctx.callback_data
  when 'opt1'
    ctx.answer_callback_query('You chose Option 1')
    ctx.edit_message_text('You selected Option 1')
  when 'opt2'
    ctx.answer_callback_query('You chose Option 2')
    ctx.edit_message_text('You selected Option 2')
  when 'help'
    ctx.answer_callback_query('Help coming soon')
    ctx.edit_message_text('Help: This is a demo bot')
  end
end

bot.start_polling
```

## Reply Keyboard Bot

```ruby
require 'telegem'

bot = Telegem.new(token: 'YOUR_BOT_TOKEN')

bot.command('keyboard') do |ctx|
  keyboard = Telegem.reply_keyboard do |kb|
    kb.row('Button 1', 'Button 2')
    kb.row('Button 3', 'Button 4')
    kb.row do
      kb.button('Remove Keyboard', request_contact: false, request_location: false)
    end
  end

  ctx.reply('Choose a button:', keyboard: keyboard)
end

bot.hears(/^Button/) do |ctx|
  ctx.reply("You pressed: #{ctx.text}")
end

bot.hears('Remove Keyboard') do |ctx|
  ctx.reply('Keyboard removed', keyboard: Telegem.remove_keyboard)
end

bot.start_polling
```

## File Handling Bot

```ruby
require 'telegem'

bot = Telegem.new(token: 'YOUR_BOT_TOKEN')

bot.document do |ctx|
  doc = ctx.message.document
  file_name = doc.file_name
  file_size = doc.file_size

  ctx.reply("Received file: #{file_name} (#{file_size} bytes)")

  # Download file
  begin
    file_content = ctx.download_file(doc.file_id)
    ctx.reply("Downloaded #{file_content.length} bytes")
  rescue => e
    ctx.reply("Failed to download file: #{e.message}")
  end
end

bot.photo do |ctx|
  photo = ctx.message.photo.last # Get highest resolution
  file_id = photo.file_id

  ctx.reply("Received photo: #{photo.width}x#{photo.height}")

  # Download and process photo
  begin
    photo_data = ctx.download_file(file_id)
    # Process photo_data...
    ctx.reply("Photo processed successfully")
  rescue => e
    ctx.reply("Failed to process photo: #{e.message}")
  end
end

bot.start_polling
```

## Scene-Based Bot (Multi-step Conversation)

```ruby
require 'telegem'

bot = Telegem.new(token: 'YOUR_BOT_TOKEN')

# Registration scene
bot.scene('register') do |scene|
  scene.step('name') do |ctx|
    ctx.session[:name] = ctx.text
    ctx.reply('Enter your email:')
    scene.next_step
  end

  scene.step('email') do |ctx|
    ctx.session[:email] = ctx.text
    ctx.reply('Enter your age:')
    scene.next_step
  end

  scene.step('age') do |ctx|
    ctx.session[:age] = ctx.text.to_i
    ctx.reply("Registration complete!\nName: #{ctx.session[:name]}\nEmail: #{ctx.session[:email]}\nAge: #{ctx.session[:age]}")
    scene.complete
  end

  scene.on_timeout do |ctx|
    ctx.reply('Registration timed out. Start again with /register')
  end
end

bot.command('register') do |ctx|
  ctx.reply('Enter your name:')
  ctx.enter_scene('register')
end

bot.command('cancel') do |ctx|
  if ctx.current_scene
    ctx.exit_scene
    ctx.reply('Registration cancelled')
  else
    ctx.reply('No active registration')
  end
end

bot.start_polling
```

## Weather Bot

```ruby
require 'telegem'
require 'httparty'

class WeatherService
  BASE_URL = 'https://api.openweathermap.org/data/2.5'

  def initialize(api_key)
    @api_key = api_key
  end

  def get_weather(city)
    response = HTTParty.get("#{BASE_URL}/weather", query: {
      q: city,
      appid: @api_key,
      units: 'metric'
    })

    if response.success?
      data = response.parsed_response
      {
        city: data['name'],
        temp: data['main']['temp'],
        description: data['weather'].first['description'],
        humidity: data['main']['humidity']
      }
    else
      nil
    end
  end
end

bot = Telegem.new(token: 'YOUR_BOT_TOKEN')
weather_service = WeatherService.new('YOUR_OPENWEATHER_API_KEY')

bot.command('weather') do |ctx|
  city = ctx.command_args

  if city.empty?
    ctx.reply('Usage: /weather <city>')
    return
  end

  ctx.reply('Getting weather data...')

  Async do
    weather = weather_service.get_weather(city)

    if weather
      message = <<~WEATHER
      Weather in #{weather[:city]}:
      Temperature: #{weather[:temp]}°C
      Conditions: #{weather[:description]}
      Humidity: #{weather[:humidity]}%
      WEATHER

      ctx.reply(message)
    else
      ctx.reply('Could not get weather data. Check city name.')
    end
  end
end

bot.start_polling
```

## Translation Bot

```ruby
require 'telegem'
require 'telegem/plugins/translate'

bot = Telegem.new(token: 'YOUR_BOT_TOKEN')

bot.command('translate') do |ctx|
  args = ctx.command_args.split(' to ')

  if args.length != 2
    ctx.reply('Usage: /translate <text> to <language>')
    ctx.reply('Example: /translate hello world to es')
    return
  end

  text, target_lang = args

  ctx.reply('Translating...')

  Async do
    translator = Telegem::Plugins::Translate.new(text, 'auto', target_lang)
    result = translator.start_translating

    if result['error'] == 'false'
      ctx.reply("Translation: #{result['translation']}")
    else
      ctx.reply('Translation failed. Please try again.')
    end
  end
end

bot.hears(/^translate (.+) to (\w+)/) do |ctx|
  text = ctx.match[1]
  target_lang = ctx.match[2]

  translator = Telegem::Plugins::Translate.new(text, 'auto', target_lang)
  result = translator.start_translating

  if result['error'] == 'false'
    ctx.reply("Translation: #{result['translation']}")
  else
    ctx.reply('Translation failed.')
  end
end

bot.start_polling
```

## File Analysis Bot

```ruby
require 'telegem'
require 'telegem/plugins/file_extract'

bot = Telegem.new(token: 'YOUR_BOT_TOKEN')

bot.document do |ctx|
  doc = ctx.message.document
  file_name = doc.file_name

  ctx.reply("Analyzing file: #{file_name}")

  Async do
    begin
      extractor = Telegem::Plugins::FileExtract.new(ctx.bot, doc.file_id)
      result = extractor.extract

      if result[:success]
        content_preview = result[:content].first(500)
        metadata_info = result[:metadata].map { |k,v| "#{k}: #{v}" }.join("\n")

        response = <<~ANALYSIS
        File Type: #{result[:type].to_s.upcase}
        Metadata:
        #{metadata_info}

        Content Preview:
        #{content_preview}#{'...' if result[:content].length > 500}
        ANALYSIS

        ctx.reply(response)
      else
        ctx.reply("Analysis failed: #{result[:error]}")
      end
    rescue => e
      ctx.reply("Error analyzing file: #{e.message}")
    end
  end
end

bot.start_polling
```

## Admin Bot with Middleware

```ruby
require 'telegem'

bot = Telegem.new(token: 'YOUR_BOT_TOKEN')

# Admin check middleware
bot.use do |ctx, next_middleware|
  admin_ids = [123456789, 987654321] # Replace with actual admin IDs

  if ctx.from && admin_ids.include?(ctx.from.id)
    ctx.is_admin = true
  else
    ctx.is_admin = false
  end

  next_middleware.call(ctx)
end

# Logging middleware
bot.use do |ctx, next_middleware|
  start_time = Time.now
  next_middleware.call(ctx)
  duration = Time.now - start_time

  puts "[#{Time.now}] #{ctx.from&.username}: #{ctx.text} (#{duration.round(3)}s)"
end

# Admin-only commands
bot.command('stats') do |ctx|
  unless ctx.is_admin
    ctx.reply('Access denied')
    return
  end

  # Get bot statistics
  stats = {
    uptime: '24h 30m',
    messages_processed: 15420,
    active_users: 234
  }

  message = <<~STATS
  Bot Statistics:
  Uptime: #{stats[:uptime]}
  Messages: #{stats[:messages_processed]}
  Active Users: #{stats[:active_users]}
  STATS

  ctx.reply(message)
end

bot.command('broadcast') do |ctx|
  unless ctx.is_admin
    ctx.reply('Access denied')
    return
  end

  message = ctx.command_args
  if message.empty?
    ctx.reply('Usage: /broadcast <message>')
    return
  end

  # In a real bot, you'd get all user IDs from database
  user_ids = [111111, 222222, 333333] # Example user IDs

  user_ids.each do |user_id|
    begin
      bot.api.call('sendMessage', chat_id: user_id, text: message)
    rescue => e
      puts "Failed to send to #{user_id}: #{e.message}"
    end
  end

  ctx.reply("Broadcast sent to #{user_ids.length} users")
end

# Public commands
bot.command('help') do |ctx|
  help_text = <<~HELP
  Commands:
  /help - Show this help
  /info - Bot information
  HELP

  if ctx.is_admin
    help_text += "\nAdmin Commands:\n/stats - Bot statistics\n/broadcast <msg> - Send broadcast"
  end

  ctx.reply(help_text)
end

bot.command('info') do |ctx|
  ctx.reply('This is a demo admin bot with Telegem')
end

bot.start_polling
```

## E-commerce Bot

```ruby
require 'telegem'

class ProductCatalog
  def initialize
    @products = {
      '1' => { name: 'Laptop', price: 999.99, description: 'High-performance laptop' },
      '2' => { name: 'Mouse', price: 29.99, description: 'Wireless mouse' },
      '3' => { name: 'Keyboard', price: 79.99, description: 'Mechanical keyboard' }
    }
  end

  def get_product(id)
    @products[id]
  end

  def all_products
    @products
  end
end

bot = Telegem.new(token: 'YOUR_BOT_TOKEN')
catalog = ProductCatalog.new()

# Session-based shopping cart
bot.use Telegem::Session::Middleware.new

bot.command('shop') do |ctx|
  keyboard = Telegem.inline_keyboard do |kb|
    catalog.all_products.each do |id, product|
      kb.row do
        kb.button("#{product[:name]} - $#{product[:price]}", callback_data: "view_#{id}")
      end
    end
  end

  ctx.reply('Welcome to our shop! Choose a product:', keyboard: keyboard)
end

bot.callback_query(/^view_/) do |ctx|
  product_id = ctx.callback_data.sub('view_', '')
  product = catalog.get_product(product_id)

  if product
    keyboard = Telegem.inline_keyboard do |kb|
      kb.row do
        kb.button('Add to Cart', callback_data: "add_#{product_id}")
        kb.button('Back to Shop', callback_data: 'shop')
      end
    end

    message = <<~PRODUCT
    #{product[:name]}
    Price: $#{product[:price]}
    Description: #{product[:description]}
    PRODUCT

    ctx.edit_message_text(message, keyboard: keyboard)
  else
    ctx.answer_callback_query('Product not found')
  end
end

bot.callback_query(/^add_/) do |ctx|
  product_id = ctx.callback_data.sub('add_', '')
  product = catalog.get_product(product_id)

  if product
    ctx.session[:cart] ||= []
    ctx.session[:cart] << product_id

    cart_count = ctx.session[:cart].length
    ctx.answer_callback_query("Added to cart! Items in cart: #{cart_count}")

    # Update message with cart count
    ctx.edit_message_reply_markup(
      keyboard: Telegem.inline_keyboard do |kb|
        kb.row do
          kb.button("View Cart (#{cart_count})", callback_data: 'cart')
          kb.button('Continue Shopping', callback_data: 'shop')
        end
      end
    )
  end
end

bot.callback_query('cart') do |ctx|
  cart = ctx.session[:cart] || []

  if cart.empty?
    ctx.edit_message_text('Your cart is empty')
    return
  end

  total = 0
  message = "Your Cart:\n\n"

  cart.each do |product_id|
    product = catalog.get_product(product_id)
    if product
      message += "#{product[:name]} - $#{product[:price]}\n"
      total += product[:price]
    end
  end

  message += "\nTotal: $#{total.round(2)}"

  keyboard = Telegem.inline_keyboard do |kb|
    kb.row do
      kb.button('Checkout', callback_data: 'checkout')
      kb.button('Clear Cart', callback_data: 'clear_cart')
      kb.button('Continue Shopping', callback_data: 'shop')
    end
  end

  ctx.edit_message_text(message, keyboard: keyboard)
end

bot.callback_query('clear_cart') do |ctx|
  ctx.session[:cart] = []
  ctx.edit_message_text('Cart cleared!')
end

bot.callback_query('checkout') do |ctx|
  cart = ctx.session[:cart] || []

  if cart.empty?
    ctx.answer_callback_query('Your cart is empty')
    return
  end

  # In a real bot, you'd process payment here
  ctx.session[:cart] = []
  ctx.edit_message_text('Thank you for your purchase! Your order has been processed.')
end

bot.callback_query('shop') do |ctx|
  # Re-show shop
  keyboard = Telegem.inline_keyboard do |kb|
    catalog.all_products.each do |id, product|
      kb.row do
        kb.button("#{product[:name]} - $#{product[:price]}", callback_data: "view_#{id}")
      end
    end
  end

  ctx.edit_message_text('Welcome to our shop! Choose a product:', keyboard: keyboard)
end

bot.start_polling
```

## Reminder Bot

```ruby
require 'telegem'

bot = Telegem.new(token: 'YOUR_BOT_TOKEN')

# Use session to store reminders
bot.use Telegem::Session::Middleware.new

bot.command('remind') do |ctx|
  args = ctx.command_args.split(' in ')

  if args.length != 2
    ctx.reply('Usage: /remind <message> in <time>')
    ctx.reply('Example: /remind Buy milk in 5 minutes')
    return
  end

  message, time_spec = args

  # Parse time (simple implementation)
  minutes = parse_time(time_spec)

  if minutes.nil?
    ctx.reply('Invalid time format. Use: 5 minutes, 1 hour, 30 seconds, etc.')
    return
  end

  # Store reminder
  ctx.session[:reminders] ||= []
  reminder = {
    message: message,
    time: Time.now + (minutes * 60),
    id: rand(1000000)
  }

  ctx.session[:reminders] << reminder

  ctx.reply("Reminder set: '#{message}' in #{minutes} minutes")

  # Schedule reminder (in real bot, use a job queue)
  Async do
    sleep(minutes * 60)
    ctx.reply("⏰ Reminder: #{message}")
  end
end

bot.command('list') do |ctx|
  reminders = ctx.session[:reminders] || []

  if reminders.empty?
    ctx.reply('No active reminders')
    return
  end

  message = "Your reminders:\n\n"
  reminders.each_with_index do |reminder, index|
    time_left = ((reminder[:time] - Time.now) / 60).round
    message += "#{index + 1}. #{reminder[:message]} (in #{time_left} minutes)\n"
  end

  ctx.reply(message)
end

bot.command('cancel') do |ctx|
  reminders = ctx.session[:reminders] || []

  if reminders.empty?
    ctx.reply('No active reminders to cancel')
    return
  end

  keyboard = Telegem.inline_keyboard do |kb|
    reminders.each_with_index do |reminder, index|
      kb.row do
        kb.button("Cancel: #{reminder[:message][0..20]}...", callback_data: "cancel_#{reminder[:id]}")
      end
    end
  end

  ctx.reply('Select reminder to cancel:', keyboard: keyboard)
end

bot.callback_query(/^cancel_/) do |ctx|
  reminder_id = ctx.callback_data.sub('cancel_', '').to_i

  reminders = ctx.session[:reminders] || []
  reminder = reminders.find { |r| r[:id] == reminder_id }

  if reminder
    ctx.session[:reminders].delete(reminder)
    ctx.edit_message_text("Reminder cancelled: #{reminder[:message]}")
  else
    ctx.answer_callback_query('Reminder not found')
  end
end

def parse_time(time_spec)
  match = time_spec.match(/(\d+)\s*(second|minute|hour|day)s?/)
  return nil unless match

  value = match[1].to_i
  unit = match[2]

  case unit
  when 'second' then value / 60.0  # Convert to minutes
  when 'minute' then value
  when 'hour' then value * 60
  when 'day' then value * 24 * 60
  end
end

bot.start_polling
```

These examples demonstrate various bot patterns and use cases. Each example can be extended and customized based on specific requirements.</content>
<parameter name="filePath">/home/slick/telegem/docs/examples.md

```ruby
require 'telegem'

# 1. Create bot
bot = Telegem.new(ENV['PIZZA_BOT_TOKEN'])

# 2. Welcome command
bot.command('start') do |ctx|
  ctx.reply "🍕 Welcome to PizzaBot!"
  ctx.reply "Use /order to start ordering"
  ctx.reply "Use /menu to see options"
end

# 3. Menu command
bot.command('menu') do |ctx|
  menu = <<~MENU
    *Our Menu:*
    
    🍕 Pizzas:
    - Margherita: $10
    - Pepperoni: $12
    - Veggie: $11
    
    🥤 Drinks:
    - Cola: $2
    - Water: $1
    
    Use /order to order!
  MENU
  
  ctx.reply menu, parse_mode: 'Markdown'
end

# 4. Order command - Starts a scene
bot.scene :ordering do
  step :choose_pizza do |ctx|
    keyboard = ctx.keyboard do
      row "Margherita", "Pepperoni"
      row "Veggie", "Cancel"
    end
    
    ctx.reply "Choose your pizza:", reply_markup: keyboard
  end
  
  step :save_pizza do |ctx|
    ctx.session[:pizza] = ctx.message.text
    ctx.reply "Great! #{ctx.session[:pizza]} selected."
    ctx.reply "What's your address?"
  end
  
  step :save_address do |ctx|
    ctx.session[:address] = ctx.message.text
    
    # Show summary
    summary = <<~SUMMARY
      *Order Summary:*
      
      Pizza: #{ctx.session[:pizza]}
      Address: #{ctx.session[:address]}
      
      Confirm? (Yes/No)
    SUMMARY
    
    ctx.reply summary, parse_mode: 'Markdown'
  end
  
  step :confirm do |ctx|
    if ctx.message.text.downcase == 'yes'
      ctx.reply "✅ Order placed! Delivery in 30 minutes."
      ctx.reply "Use /track to track your order"
    else
      ctx.reply "❌ Order cancelled."
    end
    ctx.leave_scene
  end
  
  # Handle "Cancel" at any step
  on_enter do |ctx|
    ctx.session[:order_id] = rand(1000..9999)
  end
end

# 5. Start the order scene
bot.command('order') do |ctx|
  ctx.enter_scene(:ordering)
end

# 6. Track order (simple version)
bot.command('track') do |ctx|
  if ctx.session[:order_id]
    ctx.reply "Order ##{ctx.session[:order_id]} is being prepared!"
  else
    ctx.reply "No active order. Use /order to start."
  end
end

# 7. Handle keyboard button presses
bot.on(:message) do |ctx|
  # Skip if it's a command or in scene
  next if ctx.message.command? || ctx.scene
  
  text = ctx.message.text
  
  case text
  when "Margherita", "Pepperoni", "Veggie"
    ctx.reply "Use /order to order a #{text} pizza!"
  when "Cancel"
    ctx.reply "Cancelled."
  end
end

# 8. Start bot
if ENV['WEBHOOK']
  bot.webhook_server(port: ENV['PORT'] || 3000).run
else
  puts "🍕 PizzaBot starting..."
  bot.start_polling
end
```

---

🧪 Let's Test It!

Create the file:

```bash
mkdir -p examples
touch examples/pizza_bot.rb
```

Run it:

```bash
# Set your token
export PIZZA_BOT_TOKEN="123456:your_token_here"

# Run the bot
ruby examples/pizza_bot.rb
```

Test the flow:

1. /start → Shows welcome
2. /menu → Shows pizza menu
3. /order → Starts ordering scene
4. Choose "Margherita" → Asks for address
5. Type your address → Shows summary
6. Type "yes" → Order confirmed!
7. /track → Shows order status

---

🏗️ Your Homework:

Can you add:

1. A /help command showing all commands?
2. A "size" step in the scene (Small/Medium/Large)?
3. A middleware that logs all orders to a file?

This is how you learn: Build, break, fix, improve. You now understand then library enough to code without AI help!

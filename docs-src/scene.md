
# Scenes: Multi-Step Conversations

## What Are Scenes?

Think of a scene as a **conversation flow** or **wizard**. It's like when you call customer service and they guide you through steps:

1. "Press 1 for sales"
2. "Enter your account number"
3. "Describe your issue"
4. "Confirm details"

Each step depends on the previous one. That's what scenes do for your bot.

## Why Use Scenes?

Without scenes, handling multi-step conversations looks like this:
```ruby
# ❌ Messy without scenes
if ctx.session[:step] == "ask_name"
  # Handle name
elsif ctx.session[:step] == "ask_age"
  # Handle age
elsif ctx.session[:step] == "ask_email"
  # Handle email
# ... gets messy fast!
```

With scenes, it's organized:

```ruby
# ✅ Clean with scenes
scene.step(:ask_name) { ... }
scene.step(:ask_age) { ... }
scene.step(:ask_email) { ... }
```

Real-World Example: Restaurant Order

Without scene: Chaotic back-and-forth
With scene: Guided experience:

1. Welcome → Choose food type
2. Choose size → Choose toppings
3. Enter address → Confirm order
4. Payment → Receipt

Creating Your First Scene

```ruby
# Define a scene called :survey
bot.scene(:survey) do |scene|
  # Step 1: Ask for name
  scene.step(:ask_name) do |ctx|
    ctx.reply("What's your name?")
    # Move to next step automatically
  end
  
  # Step 2: Ask for age (runs after user responds)
  scene.step(:ask_age) do |ctx|
    # Previous response is in ctx.message.text
    name = ctx.message.text
    ctx.session[:name] = name
    
    ctx.reply("Nice to meet you, #{name}! How old are you?")
  end
  
  # Step 3: Ask for favorite color
  scene.step(:ask_color) do |ctx|
    age = ctx.message.text
    ctx.session[:age] = age
    
    # Show inline keyboard for colors
    keyboard = Telegem.inline do
      row button "🔴 Red", callback_data: "color_red"
      row button "🔵 Blue", callback_data: "color_blue"
      row button "🟢 Green", callback_data: "color_green"
    end
    
    ctx.reply("Choose your favorite color:", reply_markup: keyboard)
  end
  
  # Step 4: Show results
  scene.step(:show_results) do |ctx|
    color = ctx.data.split("_").last  # "red", "blue", or "green"
    ctx.session[:color] = color
    
    # Gather all answers
    name = ctx.session[:name]
    age = ctx.session[:age]
    
    ctx.reply(<<~RESULTS)
      📝 Survey Complete!
      
      Name: #{name}
      Age: #{age}
      Favorite Color: #{color.capitalize}
      
      Thanks for participating! 🎉
    RESULTS
    
    # Exit the scene
    ctx.leave_scene
  end
end
```

Starting a Scene

```ruby
# Start the survey when user sends /survey
bot.command("survey") do |ctx|
  ctx.enter_scene(:survey)
end
```

How Scenes Work Under the Hood

1. Enter scene: ctx.enter_scene(:survey) sets current scene
2. First step runs: Scene executes :ask_name step
3. User responds: Bot receives their name
4. Auto-advance: Scene automatically moves to :ask_age
5. Continue: Process repeats through all steps
6. Exit: ctx.leave_scene ends the conversation

Scene Events

on_enter (When Scene Starts)

```ruby
bot.scene(:order) do |scene|
  scene.on_enter do |ctx|
    ctx.reply("🍕 Welcome to PizzaBot!")
    ctx.reply("Let's create your perfect pizza...")
  end
  
  # ... steps here
end
```

on_leave (When Scene Ends)

```ruby
bot.scene(:order) do |scene|
  # ... steps here
  
  scene.on_leave do |ctx|
    ctx.reply("Thanks for ordering! 🎉")
    ctx.reply("Your pizza will arrive in 30 minutes!")
  end
end
```

Managing Scene Flow

Moving Between Steps

```ruby
bot.scene(:quiz) do |scene|
  scene.step(:question1) do |ctx|
    ctx.reply("What's 2 + 2?")
    
    # You DON'T need to manually move to next step
    # It happens automatically after user responds
  end
  
  scene.step(:question2) do |ctx|
    # ctx.message.text contains answer to question1
    answer1 = ctx.message.text
    
    if answer1 == "4"
      ctx.reply("✅ Correct! Next question...")
      ctx.session[:score] += 1
    else
      ctx.reply("❌ Wrong. The answer is 4. Next question...")
    end
    
    ctx.reply("What's the capital of France?")
  end
end
```

Conditional Steps

```ruby
bot.scene(:registration) do |scene|
  scene.step(:ask_if_adult) do |ctx|
    keyboard = Telegem.inline do
      row button "✅ Yes, I'm 18+", callback_data: "adult_yes"
      row button "❌ No, I'm under 18", callback_data: "adult_no"
    end
    
    ctx.reply("Are you 18 or older?", reply_markup: keyboard)
  end
  
  scene.step(:adult_path) do |ctx|
    # Only runs if user selected "Yes"
    ctx.reply("Great! Let's continue with registration...")
    # ... adult registration steps
  end
  
  scene.step(:minor_path) do |ctx|
    # Only runs if user selected "No"
    ctx.reply("Sorry, you must be 18 or older to register.")
    ctx.leave_scene
  end
  
  # Route based on choice
  scene.on_enter do |ctx|
    # Set up routing
  end
end
```

Scene Persistence

Scenes remember where users are, even if they stop and come back later.

```ruby
# User starts survey
# -> Step 1: Asks name
# User disappears for 3 hours
# User comes back, types anything
# -> Step 2: Asks age (remembers they're in survey!)

bot.on(:message) do |ctx|
  if ctx.scene  # User is in a scene
    # Scene automatically continues from where they left off
    # You don't need to handle this manually!
  end
end
```

Practical Examples

Example 1: Pizza Order Scene

```ruby
bot.scene(:pizza_order) do |scene|
  scene.on_enter do |ctx|
    ctx.reply("Let's order a pizza! 🍕")
  end
  
  scene.step(:choose_size) do |ctx|
    keyboard = Telegem.keyboard do
      row "Small", "Medium", "Large"
    end
    
    ctx.reply("Choose pizza size:", reply_markup: keyboard)
  end
  
  scene.step(:choose_toppings) do |ctx|
    ctx.session[:size] = ctx.message.text
    
    keyboard = Telegem.inline do
      row button "Cheese", callback_data: "topping_cheese"
      row button "Pepperoni", callback_data: "topping_pepperoni"
      row button "Veggie", callback_data: "topping_veggie"
    end
    
    ctx.reply("Choose toppings:", reply_markup: keyboard)
  end
  
  scene.step(:confirm) do |ctx|
    ctx.session[:topping] = ctx.data.split("_").last
    
    ctx.reply(<<~CONFIRM
      ✅ Order Summary:
      
      Size: #{ctx.session[:size]}
      Topping: #{ctx.session[:topping]}
      
      Type CONFIRM to place order or CANCEL to stop.
    CONFIRM
    )
  end
  
  scene.step(:finalize) do |ctx|
    if ctx.message.text == "CONFIRM"
      ctx.reply("🎉 Order placed! Arriving in 30 minutes.")
      # Save order to database...
    else
      ctx.reply("Order cancelled.")
    end
    
    ctx.leave_scene
  end
  
  scene.on_leave do |ctx|
    ctx.reply("Thanks for using PizzaBot! 🍕")
  end
end
```

Example 2: Support Ticket Scene

```ruby
bot.scene(:support_ticket) do |scene|
  scene.step(:describe_issue) do |ctx|
    ctx.reply("Please describe your issue:")
  end
  
  scene.step(:ask_priority) do |ctx|
    ctx.session[:issue] = ctx.message.text
    
    keyboard = Telegem.inline do
      row button "🚨 Urgent", callback_data: "priority_high"
      row button "⚠️ Medium", callback_data: "priority_medium"
      row button "✅ Low", callback_data: "priority_low"
    end
    
    ctx.reply("How urgent is this?", reply_markup: keyboard)
  end
  
  scene.step(:ask_contact) do |ctx|
    ctx.session[:priority] = ctx.data.split("_").last
    
    keyboard = Telegem.keyboard do
      request_contact("📞 Share Phone Number")
    end
    
    ctx.reply("Please share your contact:", reply_markup: keyboard)
  end
  
  scene.step(:finish) do |ctx|
    ctx.session[:contact] = ctx.message.contact.phone_number
    
    # Create ticket in database
    ticket_id = create_ticket(
      issue: ctx.session[:issue],
      priority: ctx.session[:priority],
      contact: ctx.session[:contact]
    )
    
    ctx.reply("Ticket ##{ticket_id} created! We'll contact you soon.")
    ctx.leave_scene
  end
end
```

Best Practices

1. Keep Steps Focused

```ruby
# ❌ Don't do too much in one step
scene.step(:collect_all_info) do |ctx|
  ctx.reply("What's your name, age, email, and address?")
  # User will get confused!
end

# ✅ Split into focused steps
scene.step(:ask_name) { ctx.reply("Name?") }
scene.step(:ask_age) { ctx.reply("Age?") }
scene.step(:ask_email) { ctx.reply("Email?") }
```

2. Clear Exit Points

```ruby
bot.scene(:shopping) do |scene|
  # Allow exit at any point
  scene.step(:browse) do |ctx|
    if ctx.message.text == "/cancel"
      ctx.reply("Shopping cancelled.")
      ctx.leave_scene
      return
    end
    # ... continue shopping
  end
end
```

3. Use Session Wisely

```ruby
bot.scene(:form) do |scene|
  scene.on_enter do |ctx|
    # Initialize session
    ctx.session[:form_data] = {}
  end
  
  scene.step(:step1) do |ctx|
    # Store in session
    ctx.session[:form_data][:name] = ctx.message.text
  end
  
  scene.on_leave do |ctx|
    # Save complete form
    save_form(ctx.session[:form_data])
    # Clear session
    ctx.session.delete(:form_data)
  end
end
```

Common Patterns

Pattern 1: Branching Scenes

```ruby
# Main menu scene
bot.scene(:main_menu) do |scene|
  scene.step(:show_options) do |ctx|
    keyboard = Telegem.keyboard do
      row "Order Food", "Book Table"
      row "Contact Support", "Leave Feedback"
    end
    ctx.reply("Main Menu:", reply_markup: keyboard)
  end
  
  scene.step(:handle_choice) do |ctx|
    case ctx.message.text
    when "Order Food"
      ctx.leave_scene
      ctx.enter_scene(:food_order)
    when "Book Table"
      ctx.leave_scene
      ctx.enter_scene(:table_booking)
    # ... other choices
    end
  end
end
```

Pattern 2: Timeout Handling

```ruby
bot.scene(:quick_quiz) do |scene|
  scene.on_enter do |ctx|
    # Set timeout (user has 60 seconds to complete)
    ctx.session[:quiz_start] = Time.now
  end
  
  # In each step
  scene.step(:question) do |ctx|
    if Time.now - ctx.session[:quiz_start] > 60
      ctx.reply("⏰ Time's up! Quiz expired.")
      ctx.leave_scene
      return
    end
    # Continue quiz
  end
end
```

Troubleshooting

Scene Not Starting?

```ruby
# Make sure you're entering the scene correctly
bot.command("start_quiz") do |ctx|
  ctx.enter_scene(:quiz)  # ✅ Correct
  # NOT: bot.scene(:quiz) ❌
end
```

Scene Stuck?

```ruby
# Check if user is in a scene
bot.command("status") do |ctx|
  if ctx.scene
    ctx.reply("You're in scene: #{ctx.scene}")
  else
    ctx.reply("No active scene")
  end
end

# Force leave scene
bot.command("cancel") do |ctx|
  ctx.leave_scene
  ctx.reply("Scene cancelled.")
end
```

When to Use Scenes

✅ Perfect for:

· Multi-step forms (registration, surveys)
· Order flows (e-commerce, food)
· Onboarding processes
· Complex configuration
· Interactive tutorials

❌ Not needed for:

· Simple commands (/start, /help)
· One-time responses
· Broadcast messages
· Simple Q&A

Summary

Scenes turn chaotic conversations into guided experiences. They:

1. Organize multi-step flows
2. Remember where users left off
3. Automate step progression
4. Clean up after completion

Start with simple 2-3 step scenes, then build more complex ones as you get comfortable!

Next: Learn about Session Management to store user data between conversations.

```
```
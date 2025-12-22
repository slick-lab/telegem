🧠 Telegem Scenes: The Complete Guide (Without the Confusion)

Scenes are conversation flows in Telegem. They handle back-and-forth interactions like forms, surveys, or onboarding. Let's remove all confusion.

📖 The Two-Step Dance: Define vs. Start

Scenes work in two distinct phases:

```ruby
# PHASE 1: DEFINE (Write the script)
bot.scene :registration do
  step :ask_name { |ctx| ctx.reply "What's your name?" }
  step :ask_email { |ctx| ctx.reply "What's your email?" }
end

# PHASE 2: START (Run the script)
bot.command('register') do |ctx|
  ctx.enter_scene(:registration)  # This actually begins the scene
end
```

🎯 The Analogy That Makes Sense

· bot.scene = Writing a movie script
· ctx.enter_scene = Yelling "Action!" on set
· The scene steps = What the actors actually do

🔧 The Complete Working Template

```ruby
require 'telegem'

bot = Telegem.new('YOUR_BOT_TOKEN')

# =============== DEFINE THE SCENE ===============
bot.scene :feedback do
  # Optional: Runs when scene starts
  on_enter do |ctx|
    ctx.session[:feedback] = { user_id: ctx.from.id }
    ctx.reply "📝 Let's collect your feedback!"
  end
  
  # Step 1: Ask for rating
  step :ask_rating do |ctx|
    keyboard = Telegem::Markup.inline do
      row callback("⭐️ 1", "rating_1"), callback("⭐️ 2", "rating_2")
      row callback("⭐️ 3", "rating_3"), callback("⭐️ 4", "rating_4"), callback("⭐️ 5", "rating_5")
    end
    ctx.reply "How would you rate us? (1-5 stars)", reply_markup: keyboard
  end
  
  # Step 2: Handle rating choice
  step :handle_rating do |ctx|
    if ctx.data&.start_with?('rating_')
      rating = ctx.data.split('_').last.to_i
      ctx.session[:feedback][:rating] = rating
      ctx.reply "Thanks! Now please share your comments:"
    else
      ctx.reply "Please use the buttons above ⬆️"
      return  # Stay on this step
    end
  end
  
  # Step 3: Collect comments
  step :collect_comments do |ctx|
    if ctx.message.text
      ctx.session[:feedback][:comments] = ctx.message.text
      
      # Show summary
      summary = <<~SUMMARY
        📋 **Feedback Summary:**
        
        Rating: #{ctx.session[:feedback][:rating]} stars
        Comments: #{ctx.session[:feedback][:comments]}
        
        Submit? (yes/no)
      SUMMARY
      
      ctx.reply summary, parse_mode: 'Markdown'
    end
  end
  
  # Step 4: Final confirmation
  step :confirm do |ctx|
    if ctx.message.text&.downcase == 'yes'
      save_feedback(ctx.session[:feedback])
      ctx.reply "✅ Feedback submitted! Thank you."
    else
      ctx.reply "❌ Feedback cancelled."
    end
    ctx.leave_scene
  end
  
  # Optional: Runs when scene ends (success or cancel)
  on_leave do |ctx|
    ctx.session.delete(:feedback)
    ctx.reply "Back to main menu!"
  end
end

# =============== START THE SCENE ===============
bot.command('feedback') do |ctx|
  ctx.enter_scene(:feedback)  # THIS actually starts it
end

# Start the bot
bot.start_polling
```

📦 4 Production-Ready Scene Templates

Template 1: Simple Form (Beginner Friendly)

Perfect for basic data collection.

```ruby
bot.scene :quick_survey do
  on_enter { |ctx| ctx.reply "Quick 3-question survey:" }
  
  step :q1 do |ctx|
    ctx.reply "1. What's your favorite language? (Ruby/JS/Python)"
  end
  
  step :q2 do |ctx|
    ctx.session[:lang] = ctx.message.text
    ctx.reply "2. How many years experience?"
  end
  
  step :q3 do |ctx|
    ctx.session[:exp] = ctx.message.text
    ctx.reply "3. What's your biggest challenge?"
  end
  
  step :finish do |ctx|
    ctx.session[:challenge] = ctx.message.text
    save_survey(ctx.session)
    ctx.reply "✅ Survey complete! Thanks for sharing."
    ctx.leave_scene
  end
end

# Usage: /survey
bot.command('survey') { |ctx| ctx.enter_scene(:quick_survey) }
```

Template 2: Menu Navigator (With Branching)

For complex flows with different paths.

```ruby
bot.scene :support_ticket do
  step :ask_type do |ctx|
    keyboard = Telegem::Markup.keyboard do
      row "🐛 Bug Report", "✨ Feature Request"
      row "❓ Question", "🔧 Technical Issue"
    end
    ctx.reply "What type of support do you need?", reply_markup: keyboard
  end
  
  step :collect_details do |ctx|
    type = ctx.message.text
    ctx.session[:ticket_type] = type
    
    case type
    when "🐛 Bug Report"
      ctx.reply "Describe the bug (steps to reproduce):"
      ctx.session[:next_action] = :save_bug
    when "✨ Feature Request"
      ctx.reply "Describe the feature you'd like:"
      ctx.session[:next_action] = :save_feature
    else
      ctx.reply "Describe your issue:"
      ctx.session[:next_action] = :save_general
    end
  end
  
  step :process_ticket do |ctx|
    description = ctx.message.text
    ticket_id = "TICKET-#{SecureRandom.hex(4).upcase}"
    
    case ctx.session[:next_action]
    when :save_bug
      save_to_database(type: 'bug', desc: description, id: ticket_id)
      ctx.reply "🐛 Bug logged as #{ticket_id}"
    when :save_feature
      save_to_database(type: 'feature', desc: description, id: ticket_id)
      ctx.reply "✨ Feature requested as #{ticket_id}"
    end
    
    ctx.leave_scene
  end
  
  on_leave do |ctx|
    ctx.reply "Support will contact you soon. Use /status to check ticket."
  end
end

# Usage: /support
bot.command('support') { |ctx| ctx.enter_scene(:support_ticket) }
```

Template 3: Async Data Fetching (Advanced)

For scenes that need to fetch external data.

```ruby
bot.scene :github_analyzer do
  step :ask_repo do |ctx|
    ctx.reply "Enter a GitHub repo URL (e.g., https://github.com/user/repo):"
  end
  
  step :fetch_data do |ctx|
    url = ctx.message.text
    
    # Show loading
    ctx.reply "⏳ Fetching repo data..."
    
    # Async HTTP request
    Async do
      begin
        # Fetch from GitHub API using httpx
        data = await fetch_github_data(url)
        
        # Show results
        info = <<~INFO
          📊 **Repo Analysis:**
          
          Name: #{data[:name]}
          Stars: #{data[:stars]}
          Language: #{data[:language]}
          Description: #{data[:description]}
          
          Last updated: #{data[:updated_at]}
        INFO
        
        ctx.reply info, parse_mode: 'Markdown'
        
      rescue => e
        ctx.reply "❌ Error: #{e.message}"
      ensure
        ctx.leave_scene
      end
    end
  end
end

# Usage: /analyze
bot.command('analyze') { |ctx| ctx.enter_scene(:github_analyzer) }
```

Template 4: Multi-Step With Validation (Production Ready)

Includes proper error handling and validation.

```ruby
bot.scene :user_registration, timeout: 300 do  # 5 minute timeout
  on_enter do |ctx|
    ctx.session[:registration] = {
      started_at: Time.now,
      attempts: 0,
      data: {}
    }
    ctx.reply "👤 Registration Process\n\nLet's get started!"
  end
  
  step :ask_email do |ctx|
    ctx.reply "Enter your email address:"
  end
  
  step :validate_email do |ctx|
    email = ctx.message.text.strip
    
    unless email.include?('@') && email.include?('.')
      ctx.session[:registration][:attempts] += 1
      
      if ctx.session[:registration][:attempts] >= 3
        ctx.reply "❌ Too many attempts. Registration cancelled."
        ctx.leave_scene
        return
      end
      
      ctx.reply "❌ Invalid email format. Please try again:"
      return  # Stay on this step
    end
    
    # Email is valid
    ctx.session[:registration][:data][:email] = email
    ctx.session[:registration][:attempts] = 0
    ctx.reply "✅ Email accepted!"
    ctx.reply "Enter your full name:"
  end
  
  step :ask_password do |ctx|
    ctx.session[:registration][:data][:name] = ctx.message.text
    ctx.reply "Create a password (min 8 characters):"
  end
  
  step :confirm_registration do |ctx|
    password = ctx.message.text
    
    if password.length < 8
      ctx.reply "❌ Password too short. Min 8 characters:"
      return
    end
    
    ctx.session[:registration][:data][:password] = password
    
    # Show summary
    summary = <<~SUMMARY
      📋 **Registration Summary:**
      
      Email: #{ctx.session[:registration][:data][:email]}
      Name: #{ctx.session[:registration][:data][:name]}
      
      Confirm registration? (yes/no)
    SUMMARY
    
    ctx.reply summary, parse_mode: 'Markdown'
  end
  
  step :finalize do |ctx|
    if ctx.message.text&.downcase == 'yes'
      # Save to database
      user_id = create_user(ctx.session[:registration][:data])
      ctx.reply "✅ Registration complete!\nYour ID: #{user_id}"
    else
      ctx.reply "❌ Registration cancelled."
    end
    ctx.leave_scene
  end
  
  on_timeout do |ctx|
    ctx.reply "⏰ Registration timed out. Please start over with /register."
    ctx.session.delete(:registration)
  end
  
  on_leave do |ctx|
    # Cleanup
    ctx.session.delete(:registration)
  end
end

# Usage: /register
bot.command('register') { |ctx| ctx.enter_scene(:user_registration) }
```

🚀 Common Patterns Cheat Sheet

Pattern 1: Basic Form Flow

```ruby
bot.scene :simple_form
bot.command('start_form') { |ctx| ctx.enter_scene(:simple_form) }
```

Pattern 2: Inline Button Navigation

```ruby
bot.scene :menu_driven
# Uses callback buttons for choices
```

Pattern 3: Async Operations

```ruby
bot.scene :async_task
# Uses Async { } for HTTP/DB operations
```

Pattern 4: Validated Input

```ruby
bot.scene :validated_input
# Uses return to stay on step when validation fails
```

🔧 Debugging Scenes: Quick Fixes

❌ "Scene doesn't start!"

Check: Did you call ctx.enter_scene?

```ruby
bot.command('start') do |ctx|
  ctx.enter_scene(:your_scene)  # ← MUST BE PRESENT
end
```

❌ "Steps skip unexpectedly!"

Cause: Missing return on validation failure
Fix:

```ruby
step :collect_age do |ctx|
  age = ctx.message.text.to_i
  if age < 18
    ctx.reply "Must be 18+. Try again:"
    return  # ← THIS keeps you on the same step
  end
  # Continues only if age >= 18
end
```

❌ "Data lost between steps!"

Solution: Use ctx.session

```ruby
step :one do |ctx|
  ctx.session[:temp] = "saved data"  # ← Save
end

step :two do |ctx|
  data = ctx.session[:temp]  # ← Retrieve
end
```

📝 Remember This Mental Model

1. Define once (bot.scene) - Teach the bot a conversation pattern
2. Start many times (ctx.enter_scene) - Begin that conversation with users
3. Steps auto-advance - After user responds, Telegem moves to next step
4. Use ctx.session - Store data between steps
5. Clean up in on_leave - Remove session data when done

🎯 Your Homework (Test Understanding)

1. Create a pizza ordering scene with size and toppings
2. Add validation (size must be S/M/L, max 3 toppings)
3. Add a timeout of 10 minutes
4. Test it with /order_pizza

You now have everything you need to build robust scenes. The key is practice—start simple, then add complexity one piece at a time.
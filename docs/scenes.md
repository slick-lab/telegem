# Scene System

Scenes enable multi-step conversations and complex interaction flows. They manage state across multiple messages, perfect for forms, wizards, and guided interactions.

## What are Scenes?

Scenes are stateful conversation flows that:

- Maintain context across multiple messages
- Guide users through step-by-step processes
- Handle timeouts and cancellations
- Store temporary data during the conversation

## Basic Scene Creation

```ruby
bot.scene :registration do
  step :ask_name do |ctx|
    ctx.reply("What's your name?")
  end

  step :save_name do |ctx|
    name = ctx.message.text
    ctx.session[:user_name] = name
    ctx.reply("Hi #{name}! What's your email?")
  end

  step :complete do |ctx|
    email = ctx.message.text
    ctx.session[:user_email] = email
    ctx.reply("Registration complete!")
    ctx.leave_scene
  end
end
```

## Entering Scenes

```ruby
bot.command('register') do |ctx|
  ctx.enter_scene(:registration)
end

# With initial data
bot.command('edit_profile') do |ctx|
  ctx.enter_scene(:edit_profile, current_name: ctx.session[:name])
end
```

## Scene Methods

### Context Methods

```ruby
ctx.enter_scene(:scene_name)        # Enter a scene
ctx.leave_scene                     # Leave current scene
ctx.leave_scene(reason: :cancel)    # Leave with reason
ctx.in_scene?                       # Check if in scene
ctx.current_scene                   # Get current scene name
ctx.scene_data                      # Get scene data hash
ctx.ask("Question?")                # Ask question (helper)
ctx.next_step                       # Move to next step
ctx.next_step(:specific_step)       # Jump to specific step
```

## Scene Definition

### Basic Structure

```ruby
bot.scene :my_scene do
  # Enter callback (optional)
  on_enter do |ctx|
    ctx.reply("Welcome to the scene!")
  end

  # Leave callback (optional)
  on_leave do |ctx, reason, data|
    ctx.reply("Scene ended: #{reason}")
  end

  # Steps
  step :step1 do |ctx|
    # Step logic
  end

  step :step2 do |ctx|
    # More logic
  end
end
```

### Step Flow

Steps execute in order by default:

```ruby
bot.scene :survey do
  step :question1 do |ctx|
    ctx.ask("What's your favorite color?")
  end

  step :question2 do |ctx|
    color = ctx.message.text
    ctx.session[:color] = color
    ctx.ask("What's your age?")
  end

  step :finish do |ctx|
    age = ctx.message.text.to_i
    ctx.session[:age] = age
    ctx.reply("Thanks for the survey!")
    ctx.leave_scene
  end
end
```

### Conditional Steps

```ruby
step :check_age do |ctx|
  age = ctx.message.text.to_i

  if age < 18
    ctx.reply("Must be 18+")
    ctx.leave_scene(reason: :underage)
  else
    ctx.session[:age] = age
    ctx.next_step(:collect_email)
  end
end
```

## Advanced Scene Features

### Timeouts

```ruby
bot.scene :timed_scene do
  timeout 300  # 5 minutes

  step :start do |ctx|
    ctx.reply("You have 5 minutes...")
  end

  on_leave do |ctx, reason, data|
    if reason == :timeout
      ctx.reply("Time's up!")
    end
  end
end
```

### Scene Data

```ruby
bot.scene :form do
  step :name do |ctx|
    ctx.ask("Name?")
  end

  step :email do |ctx|
    name = ctx.scene_data[:name]  # Access previous step data
    ctx.ask("Email?")
  end
end
```

### Dynamic Scenes

```ruby
# Create scenes programmatically
def create_quiz_scene(questions)
  bot.scene :quiz do
    questions.each_with_index do |question, index|
      step "q#{index}".to_sym do |ctx|
        if index < questions.size - 1
          ctx.ask(question)
        else
          ctx.reply("Quiz complete!")
          ctx.leave_scene
        end
      end
    end
  end
end

create_quiz_scene(["Q1?", "Q2?", "Q3?"])
```

## Scene Lifecycle

### Entering a Scene

1. `on_enter` callbacks execute
2. Scene data initializes
3. First step executes

### During Scene

- Each message goes to current step handler
- `ask()` helper sets waiting state
- Steps can jump to other steps
- Data persists in `ctx.scene_data`

### Leaving a Scene

1. `on_leave` callbacks execute
2. Scene data cleans up
3. Normal message processing resumes

## Scene State Management

### Scene Data Storage

```ruby
# Scene data is stored in session
ctx.session[:telegem_scene] = {
  id: "registration",
  step: "ask_name",
  data: { name: "John" },
  entered_at: 1234567890,
  timeout: 300,
  waiting_for_response: true,
  last_question: "What's your name?"
}
```

### Accessing Scene Data

```ruby
# In scene steps
step :process do |ctx|
  data = ctx.scene_data
  name = data[:name]
  email = data[:email]
end

# Outside scenes
if ctx.in_scene?
  scene_data = ctx.session[:telegem_scene][:data]
end
```

## Error Handling

### Scene Errors

```ruby
bot.scene :error_prone do
  step :risky do |ctx|
    begin
      risky_operation()
      ctx.next_step
    rescue => e
      ctx.reply("Error occurred")
      ctx.leave_scene(reason: :error)
    end
  end
end
```

### Timeout Handling

```ruby
bot.scene :with_timeout do
  timeout 60  # 1 minute

  on_leave do |ctx, reason, data|
    case reason
    when :timeout
      ctx.reply("Scene timed out")
    when :error
      ctx.reply("Scene ended due to error")
    when :manual
      ctx.reply("Scene completed")
    end
  end
end
```

## Scene Best Practices

### Keep Scenes Focused

```ruby
# Bad: too many steps
bot.scene :everything do
  step :login
  step :select_option
  step :process_payment
  step :send_confirmation
  # 10 more steps...
end

# Good: separate scenes
bot.scene :auth do
  step :login
  step :verify
end

bot.scene :payment do
  step :select_amount
  step :process
end
```

### Validate Input

```ruby
step :collect_email do |ctx|
  email = ctx.message.text

  unless valid_email?(email)
    ctx.reply("Invalid email. Try again.")
    return  # Stay on same step
  end

  ctx.scene_data[:email] = email
  ctx.next_step
end
```

### Provide Escape Options

```ruby
bot.hears(/^cancel$/i) do |ctx|
  if ctx.in_scene?
    ctx.leave_scene(reason: :cancel)
    ctx.reply("Cancelled.")
  end
end

bot.hears(/^back$/i) do |ctx|
  if ctx.in_scene?
    # Implement back logic
    ctx.reply("Going back...")
  end
end
```

### Use Helpers

```ruby
def ask_with_validation(ctx, question, validator)
  ctx.ask(question)

  # In next step
  response = ctx.message.text
  if validator.call(response)
    # Valid
  else
    ctx.reply("Invalid input")
    # Retry
  end
end
```

## Complex Scene Examples

### Multi-choice Survey

```ruby
bot.scene :survey do
  step :start do |ctx|
    keyboard = Telegem.keyboard do
      row "Yes", "No", "Maybe"
    end

    ctx.reply("Do you like pizza?", reply_markup: keyboard)
  end

  step :follow_up do |ctx|
    answer = ctx.message.text
    ctx.scene_data[:pizza] = answer

    if answer == "Yes"
      ctx.ask("What's your favorite topping?")
    else
      ctx.reply("Survey complete!")
      ctx.leave_scene
    end
  end

  step :complete do |ctx|
    topping = ctx.message.text
    ctx.scene_data[:topping] = topping
    ctx.reply("Thanks for your feedback!")
    ctx.leave_scene
  end
end
```

### File Upload Scene

```ruby
bot.scene :upload do
  step :request_file do |ctx|
    ctx.reply("Please send me a document")
  end

  step :process_file do |ctx|
    unless ctx.message.document
      ctx.reply("Please send a document")
      return
    end

    # Process file
    file_id = ctx.message.document.file_id
    ctx.download_file(file_id, "uploads/#{file_id}")

    ctx.reply("File uploaded successfully!")
    ctx.leave_scene
  end
end
```

### Payment Flow

```ruby
bot.scene :payment do
  step :select_amount do |ctx|
    keyboard = Telegem.keyboard do
      row "$10", "$25", "$50"
    end

    ctx.reply("Select amount:", reply_markup: keyboard)
  end

  step :confirm do |ctx|
    amount = ctx.message.text.delete('$').to_i
    ctx.scene_data[:amount] = amount

    keyboard = Telegem.inline do
      callback "Confirm", "confirm_payment"
      callback "Cancel", "cancel_payment"
    end

    ctx.reply("Pay $#{amount}?", reply_markup: keyboard)
  end

  step :process do |ctx|
    # Process payment
    ctx.reply("Payment successful!")
    ctx.leave_scene
  end
end

bot.callback_query(/^confirm_payment/) do |ctx|
  ctx.answer_callback_query("Processing payment...")
  ctx.next_step(:process)
end
```

## Scene Integration with Middleware

Scenes work with the scene middleware (included by default):

```ruby
# Scene middleware intercepts updates when user is in scene
# Routes to appropriate scene step
# Handles timeouts and cleanup
```

## Testing Scenes

```ruby
# Test scene flow
def test_scene_flow
  # Enter scene
  simulate_message(bot, '/start_scene')

  # Simulate user responses
  simulate_message(bot, 'John')
  simulate_message(bot, 'john@example.com')

  # Check final state
  assert user_registered?('john@example.com')
end

# Test timeout
def test_scene_timeout
  enter_scene(:timed_scene)

  # Fast forward time
  Timecop.travel(6.minutes)

  simulate_message(bot, 'response')

  # Should have timed out
  assert !in_scene?
end
```

## Scene Limitations

- Scenes are user-specific (one scene per user)
- Scene data stored in session (memory/Redis limits apply)
- No concurrent scenes per user
- Scenes block normal message processing

## Alternative Approaches

For simple interactions, consider:

- Inline keyboards with callback queries
- State machines in session
- Multiple command handlers

Use scenes when you need:
- Guided step-by-step flows
- Temporary data collection
- Complex validation logic
- Timeout handling

Scenes are powerful for creating interactive, stateful conversations in your Telegram bot.</content>
<parameter name="filePath">/home/slick/telegem/docs/scenes.md
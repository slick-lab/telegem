
# 🚀 Quick Start: Your First Bot in 5 Minutes

Welcome! This guide will help you create your first Telegram bot with Telegem. No prior bot experience needed!

## 📋 What You'll Need

1. **Ruby installed** (version 3.0 or newer)
2. **A Telegram account**
3. **A bot token** (we'll get this next)

---

## 🔑 Step 1: Get Your Bot Token

1. Open Telegram and search for **@BotFather**
2. Start a chat and send: `/newbot`
3. Choose a name for your bot (e.g., `My Test Bot`)
4. Choose a username ending in `bot` (e.g., `my_test_123_bot`)
5. **Copy the token** that looks like this:
```

1234567890:ABCdefGHIjklMNOpqrSTUvwxYZ-123456789

```
⚠️ **Keep this token secret!** It's your bot's password.

---

## 📦 Step 2: Install Telegem

Open your terminal and run:

```bash
gem install telegem
```

You should see something like:

```
Successfully installed telegem-0.1.0
1 gem installed
```

---

🤖 Step 3: Create Your First Bot

Create a new file called my_first_bot.rb:

```ruby
# my_first_bot.rb
require 'telegem'

# 1. Paste your token here (replace the example)
BOT_TOKEN = "1234567890:ABCdefGHIjklMNOpqrSTUvwxYZ"

# 2. Create your bot
bot = Telegem.new(BOT_TOKEN)

# 3. Add your first command
bot.command('start') do |ctx|
  ctx.reply "Hello! I'm your new bot. 👋"
  ctx.reply "Try sending me /help"
end

# 4. Add a help command
bot.command('help') do |ctx|
  help_text = <<~TEXT
    🤖 **My First Bot Commands:**
    
    /start - Start the bot
    /help - Show this message
    /echo [text] - Repeat your text
    
    Just send me any message and I'll reply!
  TEXT
  
  ctx.reply help_text
end

# 5. Add an echo command
bot.command('echo') do |ctx|
  if ctx.message.text == "/echo"
    ctx.reply "Please add some text: /echo hello world"
  else
    # Remove "/echo " from the beginning
    text = ctx.message.text.sub('/echo ', '')
    ctx.reply "You said: #{text}"
  end
end

# 6. Reply to ANY message
bot.on(:message) do |ctx|
  # Don't reply to commands (they're handled above)
  next if ctx.message.command?
  
  ctx.reply "I got your message: #{ctx.message.text}"
end

# 7. Start the bot
puts "🤖 Bot starting... (Press Ctrl+C to stop)"
bot.start_polling
```

---

▶️ Step 4: Run Your Bot

In your terminal, run:

```bash
ruby my_first_bot.rb
```

You should see:

```
🤖 Bot starting... (Press Ctrl+C to stop)
```

Congratulations! Your bot is now running! 🎉

---

💬 Step 5: Test Your Bot

1. Open Telegram and search for your bot's username (e.g., @my_test_123_bot)
2. Click "Start"
3. Try these commands:
   · /start - Should say hello
   · /help - Should show commands
   · /echo hello - Should repeat "hello"
   · Send any normal message - Should echo it back

It should work like this:

```
You: /start
Bot: Hello! I'm your new bot. 👋
Bot: Try sending me /help

You: Hello bot!
Bot: I got your message: Hello bot!

You: /echo testing
Bot: You said: testing
```

---

🎨 Step 6: Add a Simple Keyboard

Let's make it more interactive! Update your bot with this:

```ruby
# Add this new command
bot.command('menu') do |ctx|
  # Create a simple keyboard
  keyboard = [
    ["Option 1", "Option 2"],
    ["Option 3", "Cancel"]
  ]
  
  ctx.reply "Choose an option:", reply_markup: { keyboard: keyboard }
end

# Handle the keyboard button presses
bot.on(:message) do |ctx|
  next if ctx.message.command?
  
  text = ctx.message.text
  
  case text
  when "Option 1"
    ctx.reply "You chose Option 1! ✅"
  when "Option 2"
    ctx.reply "Option 2 selected! 👍"
  when "Option 3"
    ctx.reply "Option 3 picked! 🎯"
  when "Cancel"
    ctx.reply "Cancelled! ❌"
  else
    ctx.reply "I got: #{text}"
  end
end
```

Restart your bot and try /menu to see the keyboard!

---

🛠️ Step 7: Common Fixes

"Token is invalid" error?

· Make sure you copied the entire token
· Check there are no spaces before/after
· Try creating a new bot with @BotFather

"gem not found" error?

· Run gem install telegem again
· Check Ruby version: ruby -v (should be 3.0+)

Bot not responding?

· Make sure your bot is running (ruby my_first_bot.rb)
· Check you've started the bot in Telegram (send /start)
· Wait a few seconds - sometimes there's a small delay

Want to stop the bot?

Press Ctrl+C in your terminal.

---

🚀 Next Steps

Your bot is working! Now try:

1. Change the replies - Make the bot say different things
2. Add more commands - Try /time to send current time
3. Send a photo - Add this to your bot:
   ```ruby
   bot.command('photo') do |ctx|
     ctx.reply "Here's a cat! 🐱"
     # Send a cat photo from the internet
     ctx.photo("https://placekitten.com/400/400")
   end
   ```
4. Check the examples - Look in the /examples folder for more ideas
5. Read the API Reference - When you're ready for more features, check api.md

---

💡 Tips for Beginners

· Save your token safely - You'll need it every time
· Restart after changes - Stop (Ctrl+C) and restart your bot when you change the code
· Start simple - Get one thing working before adding more
· Use puts for debugging - Add puts "Got here!" to see what's happening

---

🆘 Need Help?

1. Check your code against the examples above
2. Read error messages - They often tell you what's wrong
3. Ask for help - Open an issue on GitLab

---

🎉 You did it! You've built your first Telegram bot. What will you create next?

```

---

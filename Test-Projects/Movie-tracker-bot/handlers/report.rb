 class HelpHandler
     def initialize(bot)
       @bot = bot
      start_helper
     end 
   def start_helper 
      @bot.hears("🧑🏿‍✈️report_bug") do |ctx|
       ctx.reply("welcome to MovieFlix report section")
     inline = Telegem.inline do 
     url "🙋‍♀️ FAQ", "https://gitlab.com/ynwghosted/flix-faq"
    end 
       ctx.reply("👋 pls describe the issues you facing or visit our FAQ", reply_markup: inline)
       issue = ctx.message.text 
       user_id = ctx.from.id 
      if issue.nil?
        ctx.reply("whats the issue??")
     else 
        ctx.reply("issue has been submitted")
     end 
     JSON.parse(File.read('issues.json'))
    issues << {
               "text" => issue,
               "user_id" => user_id
              }
   File.write('issues.json', JSON.pretty_generate(issues))
    end 
  end 
end 

    
        
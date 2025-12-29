class PremiumHandler
    def initialize(bot)
      @bot = bot
    payment
    end 
    def payment
      @bot.hears("🤴🏼premium") do |ctx|
      ctx.typing 
     sleep 3
      ctx.reply("bot is free premium in beta")
   end 
  end 
end 
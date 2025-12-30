class SponsorHandler
 def initialize(bot)
      @bot = bot
       start_sponsoring_div
  end 
  def start_sponsoring_div
    @bot.hears("🤠sponsor") do |ctx|
          ctx.typing
             sleep 5
      ctx.reply("utimately your application will be viewed by the board")
      ctx.reply("chat with our board @darksnipe")
    end 
  end 
end 
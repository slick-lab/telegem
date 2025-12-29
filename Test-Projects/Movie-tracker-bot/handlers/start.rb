class StartHandler 
    def initialize(bot, db)
      @bot = bot
      @db = db
      start_command
      create_tables
    end 
   def start_command
     @bot.command("start") do |ctx|
        ctx.reply("welcome to MOVIE_FLIx") 
         keyboard = Telegem.keyboard do 
      row "🔃search", "〽️Add_Movie"
      row "👩‍💻help", "🧑🏿‍✈️report_bug"
      row "🤴🏼premium", "🤠sponsor"
    end 
     ctx.reply("Best flix tracker bot....", reply_markup: keyboard)
        end 
       end  
    def create_tables
  @db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS users (
      telegram_id INTEGER PRIMARY KEY,
      first_name TEXT,
      username TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  SQL
  
  @db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS movies (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT UNIQUE,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  SQL
  
  @db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS watched (
      telegram_id INTEGER,
      movie_id INTEGER,
      season INTEGER DEFAULT 1,
      episode INTEGER DEFAULT 0,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(telegram_id, movie_id)
    )
  SQL
    end 
end
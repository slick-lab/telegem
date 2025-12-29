class AddHandler
  def initialize(bot, db)
    @bot = bot
    @db = db
    setup_add_commands
  end
  
  def setup_add_commands
    # Command: /add <show_id>
    @bot.command("add") do |ctx|
      handle_add_command(ctx)
    end
  end
  
  def handle_add_command(ctx)
    
    args = ctx.message.text.split[1..-1] || []
    
    if args.empty?
      ctx.reply("❌ Usage: /add <show_id>\nExample: /add 1")
      return
    end
    
    user_id = ctx.from.id
    first_name = ctx.from.first_name
    
    
    added_shows = []
    failed_shows = []
    
    args.each do |show_id_str|
      show_id = show_id_str.to_i
      
      if show_id <= 0
        failed_shows << "#{show_id_str} (invalid ID)"
        next
      end
      
      result = subscribe_user_to_show(user_id, show_id, first_name)
      
      if result[:success]
        added_shows << result[:show_title]
      else
        failed_shows << "#{show_id_str} (#{result[:error]})"
      end
    end
    
    
    send_add_response(ctx, added_shows, failed_shows)
  end
  
  def subscribe_user_to_show(user_id, show_id, user_name)
    
    show = @db.execute(
      "SELECT id, title FROM movies WHERE id = ?",
      [show_id]
    ).first
    
    unless show
      return {success: false, error: "Show not found"}
    end
    
    show_db_id = show[0]
    show_title = show[1]
    
    
    @db.execute(
      "INSERT OR IGNORE INTO users (telegram_id, first_name) VALUES (?, ?)",
      [user_id, user_name]
    )
    
    # 3. Add to watched table (initial state: season=1, episode=0)
    @db.execute(<<-SQL, [user_id, show_db_id])
      INSERT OR IGNORE INTO watched (telegram_id, movie_id, season, episode)
      VALUES (?, ?, 1, 0)
    SQL
    
    # 4. Check if actually inserted
    inserted = @db.changes > 0
    
    if inserted
      {success: true, show_title: show_title, show_id: show_db_id}
    else
      {success: false, error: "Already subscribed"}
    end
  end
  
  def send_add_response(ctx, added_shows, failed_shows)
    response = ""
    
    if added_shows.any?
      response += "✅ *Added to your list:*\n"
      added_shows.each_with_index do |show, i|
        response += "#{i + 1}. #{show}\n"
      end
      response += "\n"
    end
    
    if failed_shows.any?
      response += "❌ *Failed to add:*\n"
      failed_shows.each do |fail|
        response += "• #{fail}\n"
      end
    end
    
    if response.empty?
      response = "⚠️ Nothing was added"
    end
    
    ctx.reply(response, parse_mode: 'Markdown')
  
  def setup_my_shows_command
    @bot.command("myshows") do |ctx|
      user_id = ctx.from.id
      
      shows = @db.execute(<<-SQL, [user_id])
        SELECT movies.id, movies.title, watched.season, watched.episode
        FROM watched
        JOIN movies ON movies.id = watched.movie_id
        WHERE watched.telegram_id = ?
        ORDER BY movies.title
      SQL
      
      if shows.empty?
        ctx.reply("📭 Your list is empty!\nUse /search to find shows, then /add <id>")
      else
        response = "📺 *Your Shows:*\n\n"
        shows.each do |id, title, season, episode|
          response += "🎬 #{title}\n"
          response += "   ID: `#{id}` | Last: S#{season}E#{episode}\n"
          response += "   /watch #{id} s#{season}e#{episode + 1}\n\n"
        end
        ctx.reply(response, parse_mode: 'Markdown')
      end
    end
  end
end
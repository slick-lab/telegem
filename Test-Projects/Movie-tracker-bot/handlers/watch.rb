class WatchHandler
  def initialize(bot, db)
    @bot = bot
    @db = db
    setup_watch_commands
    setup_inline_handlers
  end
  
  def setup_watch_commands
    # Command: /watch - Show all subscribed shows with inline buttons
    @bot.command("watch") do |ctx|
      show_watch_menu(ctx)
    end
    
    # Command: /watched <show_id> s<season>e<episode>
    @bot.command("watched") do |ctx|
      handle_watched_command(ctx)
    end
  end
  
  def show_watch_menu(ctx)
    user_id = ctx.from.id
    
    # Get user's shows with their current progress
    shows = @db.execute(<<-SQL, [user_id])
      SELECT 
        movies.id,
        movies.title,
        watched.season as current_season,
        watched.episode as current_episode
      FROM watched
      JOIN movies ON movies.id = watched.movie_id
      WHERE watched.telegram_id = ?
      ORDER BY movies.title
    SQL
    
    if shows.empty?
      ctx.reply("📭 You're not tracking any shows yet!\nUse /search to find shows, then /add <id>")
      return
    end
    
    # Create message with inline keyboard
    message = "📺 *Mark Episodes Watched*\n\n"
    message += "Click a show to mark episodes:\n\n"
    
    shows.each do |id, title, season, episode|
      message += "🎬 *#{title}*\n"
      message += "   Current: S#{season}E#{episode}\n"
      message += "   Next: S#{season}E#{episode + 1}\n\n"
    end
    
    # Create inline keyboard with ONE button per show
    inline = Telegem.inline do
      shows.each do |id, title, season, episode|
        # Button shows: "Stranger Things (S1E3)"
        row button "#{title} (S#{season}E#{episode})", 
                   callback_data: "select_show:#{id}:#{season}:#{episode}"
      end
      # Add a "Mark All Caught Up" button
      row button "✅ Mark All As Caught Up", callback_data: "catchup_all"
    end
    
    ctx.reply(message, reply_markup: inline, parse_mode: 'Markdown')
  end
  
  def setup_inline_handlers
    @bot.on(:callback_query) do |ctx|
      case ctx.data
      when /^select_show:(\d+):(\d+):(\d+)$/
        handle_show_selection(ctx, $1.to_i, $2.to_i, $3.to_i)
      when /^mark_episode:(\d+):(\d+):(\d+)$/
        handle_mark_episode(ctx, $1.to_i, $2.to_i, $3.to_i)
      when "catchup_all"
        handle_catchup_all(ctx)
      when "back_to_shows"
        show_watch_menu(ctx)
      end
    end
  end
  
  def handle_show_selection(ctx, show_id, current_season, current_episode)
    # Get show title
    show = @db.execute(
      "SELECT title FROM movies WHERE id = ?",
      [show_id]
    ).first
    
    return unless show
    
    show_title = show[0]
    
    # Create episode selection buttons
    message = "🎬 *#{show_title}*\n"
    message += "Mark which episode you watched:\n\n"
    message += "Current: S#{current_season}E#{current_episode}\n\n"
    
    # Create buttons for next 5 episodes
    inline = Telegem.inline do
      # Show 5 episodes: current+1 to current+5
      (1..5).each do |offset|
        ep_num = current_episode + offset
        row button "✅ S#{current_season}E#{ep_num}", 
                   callback_data: "mark_episode:#{show_id}:#{current_season}:#{ep_num}"
      end
      
      # Next season button
      row button "➡️ Next Season (S#{current_season + 1}E1)", 
                 callback_data: "mark_episode:#{show_id}:#{current_season + 1}:1"
      
      # Back button
      row button "🔙 Back to Shows", callback_data: "back_to_shows"
    end
    
    # Edit the message with new buttons
    ctx.edit_message_text(message, reply_markup: inline, parse_mode: 'Markdown')
    ctx.answer_callback_query(text: "Select episode for #{show_title}")
  end
  
  def handle_mark_episode(ctx, show_id, season, episode)
    user_id = ctx.from.id
    
    # Update watched table
    @db.execute(<<-SQL, [season, episode, user_id, show_id])
      UPDATE watched 
      SET season = ?, episode = ?, updated_at = CURRENT_TIMESTAMP
      WHERE telegram_id = ? AND movie_id = ?
    SQL
    
    # Get show title for response
    show = @db.execute(
      "SELECT title FROM movies WHERE id = ?",
      [show_id]
    ).first
    
    show_title = show[0] if show
    
    # Show confirmation
    ctx.answer_callback_query(
      text: "✅ Marked #{show_title} S#{season}E#{episode} as watched!"
    )
    
    # Update message to show new status
    message = "✅ *Updated!*\n\n"
    message += "🎬 #{show_title}\n"
    message += "Now watching: S#{season}E#{episode}\n"
    message += "Next alert: S#{season}E#{episode + 1}\n\n"
    message += "Click another show or use /watch again."
    
    # Keep back button
    inline = Telegem.inline do
      row button "🔙 Back to Shows", callback_data: "back_to_shows"
    end
    
    ctx.edit_message_text(message, reply_markup: inline, parse_mode: 'Markdown')
  end
  
  def handle_catchup_all(ctx)
    user_id = ctx.from.id
    
    # For each show, set episode to a high number (like 999 to mark as "caught up")
    shows_updated = @db.execute(<<-SQL, [user_id])
      UPDATE watched
      SET episode = 999, updated_at = CURRENT_TIMESTAMP
      WHERE telegram_id = ? AND episode < 999
    SQL
    
    ctx.answer_callback_query(
      text: "✅ Marked all shows as caught up!"
    )
    
    # Go back to show list
    show_watch_menu(ctx)
  end
  
  def handle_watched_command(ctx)
    # Text command version: /watched 1 s1e3
    args = ctx.message.text.split
    
    if args.size != 3
      ctx.reply("Usage: /watched <show_id> <episode>\nExample: /watched 1 s1e3")
      return
    end
    
    show_id = args[1].to_i
    episode_str = args[2]
    
    match = episode_str.match(/s(\d+)e(\d+)/i)
    unless match
      ctx.reply("❌ Invalid format. Use: s1e3, s2e5, etc.")
      return
    end
    
    season = match[1].to_i
    episode = match[2].to_i
    user_id = ctx.from.id
    
    # Update database
    @db.execute(<<-SQL, [season, episode, user_id, show_id])
      UPDATE watched 
      SET season = ?, episode = ?, updated_at = CURRENT_TIMESTAMP
      WHERE telegram_id = ? AND movie_id = ?
    SQL
    
    if @db.changes > 0
      ctx.reply("✅ Updated! You've watched up to S#{season}E#{episode}")
    else
      ctx.reply("❌ You're not tracking that show. Use /add first.")
    end
  end
end
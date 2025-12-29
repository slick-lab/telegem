require 'uri'
require 'net/http'
require 'json'

class SearchHandler
  def initialize(bot, db)
    @bot = bot
    @db = db
    setup_search_commands
  end
  
  def setup_search_commands
    # Command: /search
    @bot.hears("🔃search") do |ctx|
      ctx.reply("🎬 Search for TV shows\n\nUse: search <show name>\nExample: search Stranger Things")
    end
    
    # Hears: "search merlin" or "search stranger things"
    @bot.hears(/^\s*search\s+/i) do |ctx|
      handle_search_request(ctx)
    end
  end
  
  def handle_search_request(ctx)
    # Extract show name from message
    text = ctx.message.text
    show_name = text.sub(/^\s*search\s+/i, "").strip
    
    if show_name.empty?
      ctx.reply("❌ Please provide a show name")
      return
    end
    
    ctx.reply("🔍 Searching for '#{show_name}'...")
    
    # Step 1: Check OUR database first
    local_show = find_in_local_database(show_name)
    
    if local_show
      # Found in our DB
      send_local_result(ctx, local_show)
    else
      # Not in our DB → Search API
      api_result = search_tvmaze_api(show_name)
      
      if api_result[:error]
        ctx.reply("❌ #{api_result[:error]}")
      else
        # Save to OUR database
        saved_show = save_show_to_database(api_result)
        send_api_result(ctx, saved_show)
      end
    end
  end

  
  def find_in_local_database(show_name)
    # Search in movies table
    result = @db.execute(
      "SELECT id, title, created_at FROM movies WHERE title LIKE ? LIMIT 1",
      ["%#{show_name}%"]
    ).first
    
    return nil unless result
    
    {
      id: result[0],          
      title: result[1],       # Show title
      created_at: result[2],  # 
      source: :local_database
    }
  end
  
  def save_show_to_database(show_data)
    # Insert into movies table
    @db.execute(
      "INSERT OR IGNORE INTO movies (title) VALUES (?)",
      [show_data[:name]]
    )
    
    # Get the ID we just inserted (or existing ID)
    db_id = @db.execute(
      "SELECT id FROM movies WHERE title = ?",
      [show_data[:name]]
    ).first[0]
    
    
    {
      id: db_id,
      title: show_data[:name],
      tvmaze_id: show_data[:id],
      next_airdate: show_data[:next_airdate],
      source: :tvmaze_api
    }
  end
  
  
  
  def search_tvmaze_api(show_name)
    url = "https://api.tvmaze.com/singlesearch/shows?q=#{URI.encode_www_form_component(show_name)}&embed=nextepisode"
    
    begin
      uri = URI(url)
      response = Net::HTTP.get(uri)
      data = JSON.parse(response)
      
      if data["id"].nil?
        return { error: "Show '#{show_name}' not found on TVMaze" }
      end
      
      {
        id: data["id"],
        name: data["name"],
        air_days: data.dig("schedule", "days") || [],
        next_airdate: data.dig("_embedded", "nextepisode", "airdate"),
        summary: data["summary"] || "No summary available",
        status: data["status"] || "Unknown"
      }
    rescue => e
      return { error: "API error: #{e.message}" }
    end
  end
  
  
  
  def send_local_result(ctx, show)
    message = "✅ Found in our database!\n\n"
    message += "🎬 #{show[:title]}\n"
    message += "🆔 Our ID: #{show[:id]}\n"
    message += "📅 Added: #{show[:created_at]}\n\n"
    message += "Use /add #{show[:id]} to track this show"
    
    ctx.reply(message)
  end
  
  def send_api_result(ctx, show)
    message = "🎬 #{show[:title]}\n"
    message += "🆔 TVMaze ID: #{show[:tvmaze_id]}\n"
    message += "🆔 Our DB ID: #{show[:id]}\n"
    
    if show[:next_airdate]
      message += "📅 Next episode: #{show[:next_airdate]}\n"
    end
    
    message += "\n✅ Saved to our database!\n"
    message += "Use /add #{show[:id]} to track this show"
    
    ctx.reply(message)
  end
end
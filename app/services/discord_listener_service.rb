require 'discordrb'
require 'vader_sentiment_ruby'

class DiscordListenerService
  # You'll likely want to restrict listening to specific "high signal" channels
  # You can find these IDs by right-clicking a channel in Discord -> "Copy ID" (Developer Mode must be on)
  TARGET_CHANNEL_IDS = [
    123456789012345678, # e.g., #premier-league-betting
    987654321098765432  # e.g., #daily-picks
  ].freeze

  def initialize
    @token = Rails.application.credentials.dig(:discord, :bot_token)
    @client_id = Rails.application.credentials.dig(:discord, :client_id)
  end

  def start!
    bot = Discordrb::Bot.new(token: @token, client_id: @client_id)

    puts "🤖 StatMachine Bot is connecting..."

    # Event: Bot is ready
    bot.ready do
      puts "✅ Connected! Logged in as #{bot.profile.username}."
      puts "   Waiting for messages in server..."
    end

    # Event: Message Received
    bot.message do |event|
      # 1. Debugging Helper: Print channel ID so you can find it
      # (Remove this 'puts' later if it gets too noisy)
      puts "📩 Msg in ##{event.channel.name} (ID: #{event.channel.id}): #{event.content}"

      # 2. Filter Channels (Optional)
      # next unless TARGET_CHANNEL_IDS.empty? || TARGET_CHANNEL_IDS.include?(event.channel.id)
      
      # 3. Filter out other bots
      next if event.user.bot_account?

      process_message(event)
    end

    bot.run
  end

  private

  def process_message(event)
    content = event.content
    team = find_team_in_content(content)
    return unless team

    # CHANGE THIS LINE:
    # Old: score = @analyzer.sentiment(content)[:compound]
    # New: Use .polarity_scores directly on the module
    score = VaderSentimentRuby.polarity_scores(content)[:compound]

    log_sentiment(team, score, content, event.author.username, event.channel.name)
  end

  def find_team_in_content(content)
    # We iterate through your seeded teams to check if any aliases exist in the string.
    # Optimization: For production, you'd want a more efficient keyword scanner.
    Team.find_each do |t|
      # Check name, short_name, and all aliases
      keywords = [t.name, t.short_name, *t.aliases].compact.map(&:downcase)
      
      # If any keyword is found in the message
      if keywords.any? { |k| content.downcase.include?(k) }
        return t
      end
    end
    nil
  end

  def log_sentiment(team, score, text, author, channel)
    SentimentLog.create!(
      team: team,
      source: 'discord',
      author: author,
      raw_text: text,
      score: score,
      captured_at: Time.current
    )

    # Visual Feedback in Console
    icon = score > 0.05 ? "🟢" : (score < -0.05 ? "🔴" : "⚪")
    puts "   #{icon} [#{team.short_name}] Score: #{score} | User: #{author}"
  end
end
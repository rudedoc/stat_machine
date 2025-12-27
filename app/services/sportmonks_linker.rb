# app/services/sportmonks_linker.rb
class SportmonksLinker
  def self.link_all_upcoming!
    # Only process competitions that have a Sportmonks League ID
    Competition.where.not(sportmonks_league_id: nil).find_each do |competition|
      new(competition).link_events
    end
  end

  def initialize(competition)
    @competition = competition
    @client = SportmonksClient.new
  end

  def link_events
    # Find upcoming Betfair events for this competition missing a link
    events = @competition.events.upcoming.where(sportmonks_fixture_id: nil)
    return if events.empty?

    # Group by date to fetch all league fixtures for that day in one call
    events.group_by { |e| e.kick_off.to_date }.each do |date, daily_events|
      process_date_batch(date, daily_events)
    end
  end

  private

  def process_date_batch(date, daily_events)
    # The date is passed as part of the path segment
    endpoint = "fixtures/date/#{date.to_s}"

    response = @client.get_data(endpoint, {
      filters: "fixtureLeagues:#{@competition.sportmonks_league_id}",
      include: "participants"
    })

    sm_fixtures = response&.dig('data') || []
    return if sm_fixtures.empty?

    daily_events.each do |event|
      match = find_match(event, sm_fixtures)
      if match
        event.update!(sportmonks_fixture_id: match['id'])
        puts "✅ Linked: #{event.name} -> Sportmonks ID: #{match['id']}"
      end
    end
  end

  def find_match(event, sm_fixtures)
    sm_fixtures.find do |sm|
      # 1. Match within a 15-minute time window
      sm_time = Time.zone.parse(sm['starting_at'])
      time_match = (sm_time - event.kick_off).abs < 15.minutes

      # 2. Match based on team name prefix (e.g., "Arse" matches "Arsenal")
      # Betfair names are usually "Home v Away"
      home_prefix = event.name.split(' v ').first[0..3].downcase
      name_match = sm['name'].downcase.include?(home_prefix)

      time_match && name_match
    end
  end
end

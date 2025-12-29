class FootballApiService
  include HTTParty
  base_uri 'https://v3.football.api-sports.io'
  ENGLISH_PREMIER_LEAGUE_ID = 39

  # find the betfair team name for a given football api team name
  FOOTBALL_API_TO_BETFAIR_TEAM_NAME_MAPPINGS = {
    'Nottingham Forest' => 'Nottm Forest',
    'Manchester United' => 'Man Utd',
    'Manchester City' => 'Man City',
  }

  def initialize
    @options = {
      headers: {
        'x-apisports-key' => Rails.application.credentials.dig(:api_football, :api_key),
        'Content-Type' => 'application/json'
      }
    }
  end

  # Fetch matches for a specific league and season
  def get_matches(league_id = ENGLISH_PREMIER_LEAGUE_ID, season = 2025)
    self.class.get("/fixtures", @options.merge(query: { league: league_id, season: season }))
  end

  def get_league_schedule(league_id = ENGLISH_PREMIER_LEAGUE_ID, season = Date.today.year, from_date = Date.today, to_date = Date.today + 7)
    query = { 
      league: league_id, 
      season: season, 
      from: from_date, # "2026-01-01"
      to: to_date      # "2026-01-07"
    }
    self.class.get("/fixtures", @options.merge(query: query))
  end

  def get_prediction(fixture_id)
    self.class.get("/predictions", @options.merge(query: { fixture: fixture_id }))
  end

  def sync_matches(league_name: 'English Premier League', league_id: ENGLISH_PREMIER_LEAGUE_ID, season: Date.today.year, from_date: Date.today, to_date: Date.today + 7, rate_limit_delay: 0.2)
    response = get_league_schedule(league_id, season, from_date, to_date)
    errors = Array(response['errors']).compact
    return { success: false, error: errors } if errors.any?

    league = Competition.find_by(name: league_name)
    return { success: false, error: "Competition '#{league_name}' not found" } unless league

    matches = response['response'] || []
    summary = {
      success: true,
      total_matches: response['results'] || matches.size,
      updated_events: 0,
      skipped_events: 0,
      unmatched_fixtures: []
    }

    matches.each do |match_data|
      event = find_event_for_match(league, match_data)

      unless event
        summary[:skipped_events] += 1
        summary[:unmatched_fixtures] << match_data.dig('fixture', 'id')
        next
      end

      fixture_id = match_data.dig('fixture', 'id')
      event.update(football_api_id: fixture_id) if event.football_api_id.nil?

      prediction = fetch_prediction_for_fixture(fixture_id)
      event.update(predictions: prediction) if prediction

      summary[:updated_events] += 1
      sleep(rate_limit_delay) if rate_limit_delay.to_f.positive?
    end

    summary
  end

  private

  def find_event_for_match(league, match_data)
    fixture = match_data['fixture']
    teams = match_data['teams']
    home_name = FOOTBALL_API_TO_BETFAIR_TEAM_NAME_MAPPINGS.fetch(teams.dig('home', 'name'), teams.dig('home', 'name'))
    away_name = FOOTBALL_API_TO_BETFAIR_TEAM_NAME_MAPPINGS.fetch(teams.dig('away', 'name'), teams.dig('away', 'name'))
    kick_off = DateTime.parse(fixture['date'])
    event_name = "#{home_name} v #{away_name}".downcase

    db_event = league.events.where('lower(events.name) = ?', event_name).where('events.kick_off = ?', kick_off).first

    db_event
  end

  def fetch_prediction_for_fixture(fixture_id)
    response = get_prediction(fixture_id)
    errors = Array(response['errors']).compact
    return if errors.any?

    Array(response['response']).first
  end
end

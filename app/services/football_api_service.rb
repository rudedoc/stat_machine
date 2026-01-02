class FootballApiService
  include HTTParty
  base_uri 'https://v3.football.api-sports.io'
  ENGLISH_PREMIER_LEAGUE_ID = 39

  def initialize(league_name: 'English Premier League', league_id: ENGLISH_PREMIER_LEAGUE_ID, season: 2025, from_date: Date.today, to_date: Date.today + 7)
    @league_name = league_name
    @league_id = league_id
    @season = season
    @from_date = from_date
    @to_date = to_date
    @options = {
      headers: {
        'x-apisports-key' => Rails.application.credentials.dig(:api_football, :api_key),
        'Content-Type' => 'application/json'
      }
    }
  end

   def search_leagues(country:, season: nil)
    self.class.get("/leagues", @options.merge(query: { country: country, season: season }, timeout: 10))
  end

  # Fetch matches for a specific league and season
  def get_matches
    self.class.get("/fixtures", @options.merge(query: { league: @league_id, season: @season }))
  end

  def get_league_schedule
    query = {
      league: @league_id,
      season: @season,
      from: @from_date,
      to: @to_date
    }
    self.class.get("/fixtures", @options.merge(query: query))
  end

  def get_prediction(fixture_id)
    self.class.get("/predictions", @options.merge(query: { fixture: fixture_id }))
  end

  def sync_matches(rate_limit_delay: 0.2)
    response = get_league_schedule
    errors = Array(response['errors']).compact
    return { success: false, error: errors } if errors.any?

    league = Competition.find_by(name: @league_name)
    return { success: false, error: "Competition '#{@league_name}' not found" } unless league

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
    kick_off = DateTime.parse(fixture['date'])
    candidate_event_names = candidate_event_names_for(teams.dig('home', 'name'), teams.dig('away', 'name'))
    return if candidate_event_names.empty?

    league.events
          .where('events.kick_off = ?', kick_off)
          .where('LOWER(events.name) IN (?)', candidate_event_names)
          .first
  end

  def fetch_prediction_for_fixture(fixture_id)
    response = get_prediction(fixture_id)
    errors = Array(response['errors']).compact
    return if errors.any?

    Array(response['response']).first
  end

  def candidate_event_names_for(home_name, away_name)
    home_names = normalized_team_names(home_name)
    away_names = normalized_team_names(away_name)
    return [] if home_names.empty? || away_names.empty?

    home_names.product(away_names).map { |home, away| "#{home} v #{away}" }
  end

  def normalized_team_names(raw_name)
    normalized_input = normalize_team_name(raw_name)
    return [] if normalized_input.blank?

    tag = team_tag_for(raw_name)
    candidate_values = [raw_name]
    if tag
      candidate_values << tag.name
      candidate_values.concat(Array(tag.aliases))
    end

    candidate_values.map { |value| normalize_team_name(value) }.reject(&:blank?).uniq
  end

  def team_tag_for(raw_name)
    normalized_key = normalize_team_name(raw_name)
    return nil if normalized_key.blank?

    team_tag_cache[normalized_key] ||= Tag.identify(raw_name, category: 'team')
  end

  def team_tag_cache
    @team_tag_cache ||= {}
  end

  def normalize_team_name(value)
    value.to_s.downcase.gsub(/\s+/, ' ').strip
  end
end

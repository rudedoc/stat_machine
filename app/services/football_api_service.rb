class FootballApiService
  include HTTParty
  base_uri 'https://v3.football.api-sports.io'

  DEFAULT_LOOKAHEAD_DAYS = 7

  def self.sync_upcoming_competitions!(from_date: Date.current, to_date: Date.current + 7.days, season: 2025, rate_limit_delay: 0.2)
    start_date = normalize_date_boundary(from_date) || Date.current
    finish_date = normalize_date_boundary(to_date) || (start_date + DEFAULT_LOOKAHEAD_DAYS)

    Competition
      .where.not(football_api_league_id: nil)
      .find_each
      .with_object([]) do |competition, summaries|
        service = new(
          league_id: competition.football_api_league_id,
          season: season,
          from_date: start_date,
          to_date: finish_date
        )

        summary = service.sync_matches(rate_limit_delay: rate_limit_delay)

        summaries << {
          competition_id: competition.id,
          betfair_competition_id: competition.betfair_id,
          football_api_league_id: competition.football_api_league_id,
          summary: summary
        }
      end
  end

  def initialize(league_id:, season: nil, from_date: nil, to_date: nil)
    @league_id = league_id
    @season = season || default_season
    @from_date = normalize_date(from_date) || Date.current
    @to_date = normalize_date(to_date) || (@from_date + DEFAULT_LOOKAHEAD_DAYS)
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

    league = Competition.find_by(football_api_league_id: @league_id)
    return { success: false, error: "Competition with ID '#{@league_id}' not found" } unless league

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

  def default_season
    Date.current.year
  end

  def normalize_date(value)
    return value if value.is_a?(Date)
    return value.to_date if value.respond_to?(:to_date)

    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def self.normalize_date_boundary(value)
    return nil if value.nil?
    return value if value.is_a?(Date)
    return value.to_date if value.respond_to?(:to_date)

    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

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

    return team_tag_cache[normalized_key] if team_tag_cache.key?(normalized_key)

    tag = Tag.identify(raw_name, category: 'team')
    team_tag_cache[normalized_key] = tag
    log_missing_team_tag(raw_name) unless tag
    tag
  end

  def team_tag_cache
    @team_tag_cache ||= {}
  end

  def log_missing_team_tag(raw_name)
    self.class.missing_tag_logger.warn("Team tag not identified for '#{raw_name}'")
  end

  def self.missing_tag_logger
    @missing_tag_logger ||= ::Logger.new(Rails.root.join('log', 'football_api_missing_tags.log'))
  end

  def normalize_team_name(value)
    value.to_s.downcase.gsub(/\s+/, ' ').strip
  end
end

# app/services/sync_fixture_service.rb
class SyncFixtureService
  STATE_MAP = {
    1 => 'Scheduled',
    2 => 'In-Play',
    3 => 'Half-Time',
    5 => 'Finished',
    10 => 'Postponed',
    11 => 'Suspended',
    12 => 'Cancelled'
  }.freeze

  def self.call(data)
    new(data).sync
  end

  def initialize(data)
    @data = data
  end

  def sync
    sport = Sport.find_or_create_by!(external_id: @data['sport_id']) { |s| s.name = "Football" }

    # 1. Handle Country for the League
    league_country = find_or_sync_country(@data.dig('league', 'country_id'), @data.dig('league', 'country'))

    # 2. Define League & Season (Fixed: variables now assigned correctly)
    league = League.find_or_initialize_by(external_id: @data['league_id'])
    league.update!(
      sport: sport,
      country: league_country,
      name: @data.dig('league', 'name'),
      image_path: @data.dig('league', 'image_path')
    )

    season = Season.find_or_initialize_by(external_id: @data['season_id'])
    season.update!(league: league, name: "Season #{@data['season_id']}", is_current: true)

    # 3. Update the Fixture
    fixture = Fixture.find_or_initialize_by(external_id: @data['id'])
    fixture.update!(
      league: league,
      season: season,
      name: @data['name'],
      starting_at: @data['starting_at'],
      state_id: @data['state_id'],
      external_venue_id: @data['venue_id'],
      round_id: @data['round_id'],
      stage_id: @data['stage_id'],
      result_info: @data['result_info']
    )

    # 4. Run Nested Syncs
    sync_participants(fixture, @data['participants']) if @data['participants']
    sync_predictions(fixture, @data['predictions'])   if @data['predictions']

    fixture
  end

  private

  def find_or_sync_country(external_id, country_data = nil)
    return nil unless external_id

    # We use find_or_initialize_by to avoid the immediate validation crash
    country = Country.find_or_initialize_by(external_id: external_id)

    iso_code = country_data&.dig('iso2')

    # Logic to determine the best possible name
    resolved_name = if iso_code
                      ISO3166::Country[iso_code]&.common_name
                    end
    resolved_name ||= country_data&.dig('name')
    resolved_name ||= country.name # Keep existing name if we have one
    resolved_name ||= "Unknown Country (#{external_id})" # Absolute fallback

    country.name = resolved_name

    if iso_code
      gem_country = ISO3166::Country[iso_code]
      country.extra_data = {
        iso2: iso_code,
        iso3: country_data&.dig('iso3') || gem_country&.alpha3,
        emoji: gem_country&.emoji_flag
      }
    end

    country.image_path = country_data&.dig('image_path')

    # Use save! here to catch issues, but now we've guaranteed a name
    country.save!
    country
  end

  def sync_participants(fixture, participants_array)
    participants_array.each do |p_data|
      # Teams also have country data we can sync
      participant_country = find_or_sync_country(p_data['country_id'])

      participant = Participant.find_or_initialize_by(external_id: p_data['id'])
      participant.update!(
        sport: fixture.league.sport,
        country: participant_country,
        name: p_data['name'],
        short_code: p_data['short_code'],
        image_path: p_data['image_path'],
        founded: p_data['founded'],
        type: p_data['type'],
        gender: p_data['gender']
      )

      fp = fixture.fixture_participants.find_or_initialize_by(participant: participant)
      meta = p_data['meta'] || {}
      fp.update!(
        location: meta['location'],
        winner: meta['winner'],
        position: meta['position']
      )
    end
  end

  def sync_predictions(fixture, predictions_array)
    predictions_array.each do |pred_data|
      prediction = fixture.predictions.find_or_initialize_by(external_id: pred_data['id'])
      prediction.update!(
        type_id: pred_data['type_id'],
        predictions: pred_data['predictions']
      )
    end
  end
end

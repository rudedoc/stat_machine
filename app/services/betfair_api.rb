class BetfairApi
  BASE_URL = "https://api.betfair.com/exchange/betting/rest/v1.0/"
  LOGIN_URL = "https://identitysso.betfair.com/api/login"

  def self.import_all_data!
    api = new

    Country.sync_all!(api: api)

    Country.find_each do |country|
      Competition.sync_for_country!(country.country_code, api: api)
    end

    Competition.find_each do |competition|
      api.fetch_match_odds_by_competition(competition.betfair_id)
    end
  end

  def initialize
    @app_key = Rails.application.credentials.dig(:betfair, :app_key)
    @session_token = get_session_token
  end

  def list_countries
    payload = {
      filter: {
        eventTypeIds: ["1"],
        # Syncing the time range with list_competitions
        marketStartTime: {
          from: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
          to: 1.week.from_now.end_of_day.strftime("%Y-%m-%dT%H:%M:%SZ")
        }
      }
    }
    post_request("listCountries/", payload)
  end

  # Fetch leagues (competitions) filtered by country codes
  def list_competitions(country_codes = [])
    payload = {
      filter: {
        eventTypeIds: ["1"],
        marketCountries: Array(country_codes),
        # Filter for matches starting between now and the end of today
        marketStartTime: {
          from: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
          to: 1.week.from_now.end_of_day.strftime("%Y-%m-%dT%H:%M:%SZ")
        }
      }
    }
    post_request("listCompetitions/", payload)
  end

  def fetch_match_odds_by_competition(competition_id, persist: true)
    payload = {
      filter: {
        eventTypeIds: ["1"],
        competitionIds: [competition_id],
        marketStartTime: { from: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ") }
      }
    }
    events = post_request("listEvents/", payload)
    fetch_match_odds_for_events(events, competition_id, persist: persist) # Reuses your existing batching logic
  end

  # 2. High-level method to get Matches + Odds in one flow
  # app/services/betfair_api.rb
  def fetch_match_odds_for_events(events, betfair_competition_id = nil, persist: true)
    event_ids = events.map { |e| e.dig("event", "id") }
    return [] if event_ids.empty?

    catalogues = list_match_odds_markets(event_ids.first(50))

    # Capture the openDate (kick-off time) from the metadata
    market_metadata = catalogues.each_with_object({}) do |cat, hash|
      hash[cat["marketId"]] = {
        event_name: cat.dig("event", "name"),
        betfair_event_id: cat.dig("event", "id"),
        market_name: cat["marketName"],
        kick_off: cat.dig("event", "openDate"), # New field
        runners: cat["runners"].each_with_object({}) { |r, h| h[r["selectionId"]] = r["runnerName"] }
      }
    end

    market_ids = market_metadata.keys
    market_books = []
    market_ids.each_slice(25) { |chunk| market_books += get_market_prices_batch(chunk) }

    captured_at = Time.current
    matches = market_books.map do |book|
      metadata = market_metadata[book["marketId"]]
      next unless metadata

      runner_prices = parse_runners_with_names(book["runners"], metadata[:runners])
      runner_percentages = ProbabilityCalculator.to_percentages(runner_prices)

      {
        event_name: metadata[:event_name],
        betfair_event_id: metadata[:betfair_event_id],
        market_name: metadata[:market_name],
        kick_off: metadata[:kick_off], # Pass to final hash
        market_id: book["marketId"],
        betfair_competition_id: betfair_competition_id,
        status: book["status"],
        inplay: book["inplay"],
        runners: runner_percentages
      }
    end.compact

    if persist && matches.any?
      BetfairSnapshotPersister.new(matches: matches, captured_at: captured_at).persist!
    end

    matches
  end

  # 3. Intermediate: Find the "Match Odds" market IDs
  def list_match_odds_markets(event_ids)
    payload = {
      filter: {
        eventIds: Array(event_ids),
        marketTypeCodes: ["MATCH_ODDS"]
      },
      maxResults: 50,
      marketProjection: ["RUNNER_DESCRIPTION", "EVENT"]
    }
    post_request("listMarketCatalogue/", payload)
  end

  private

  # Gets prices for multiple markets in one API call
  def get_market_prices_batch(market_ids)
    return [] if market_ids.empty?
    payload = {
      marketIds: market_ids,
      priceProjection: { priceData: ["EX_BEST_OFFERS"] }
    }
    post_request("listMarketBook/", payload)
  end

  # Cleans up the complex nested price hash from Betfair
  def parse_runners_with_names(runners_data, runner_name_map)
    runners_data.map do |runner|
      {
        name: runner_name_map[runner["selectionId"]], # Looks up "Man Utd", etc.
        selection_id: runner["selectionId"],
        back_price: runner.dig("ex", "availableToBack", 0, "price"),
        lay_price: runner.dig("ex", "availableToLay", 0, "price")
      }
    end
  end

  def post_request(endpoint, body)
    response = Faraday.post(BASE_URL + endpoint) do |req|
      req.headers['X-Application'] = @app_key
      req.headers['X-Authentication'] = @session_token
      req.headers['Content-Type'] = 'application/json'
      req.body = body.to_json
    end
    JSON.parse(response.body)
  end

  def get_session_token
    # Cache token for 20 mins to prevent login rate-limiting
    Rails.cache.fetch("betfair_session_token", expires_in: 20.minutes) do
      response = Faraday.post(LOGIN_URL) do |req|
        req.headers['X-Application'] = @app_key
        req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        req.headers['Accept'] = 'application/json'
        req.body = URI.encode_www_form(
          username: Rails.application.credentials.dig(:betfair, :username),
          password: Rails.application.credentials.dig(:betfair, :password)
        )
      end
      JSON.parse(response.body)["token"]
    end
  end
end

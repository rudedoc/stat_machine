class BetfairApi
  BASE_URL = "https://api.betfair.com/exchange/betting/rest/v1.0/"
  LOGIN_URL = "https://identitysso.betfair.com/api/login"

  def self.import_all_data!
    api = new

    Country.sync_all!(api: api)

    Country.find_each do |country|
      # Consider adding .active scope here to skip old countries
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
        marketStartTime: {
          from: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
          to: 1.week.from_now.end_of_day.strftime("%Y-%m-%dT%H:%M:%SZ")
        }
      }
    }
    post_request("listCountries/", payload)
  end

  def list_competitions(country_codes = [])
    payload = {
      filter: {
        eventTypeIds: ["1"],
        marketCountries: Array(country_codes),
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
    fetch_match_odds_for_events(events, competition_id, persist: persist)
  end

  # Main method to fetch Matches + Odds + Volume
  def fetch_match_odds_for_events(events, betfair_competition_id = nil, persist: true)
    event_ids = events.map { |e| e.dig("event", "id") }
    return [] if event_ids.empty?

    all_matches = []

    event_ids.each_slice(50) do |events_chunk|
      catalogues = list_match_odds_markets(events_chunk)
      next if catalogues.empty?

      # ... (metadata mapping logic remains the same) ...
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

      chunk_matches = market_books.map do |book|
        metadata = market_metadata[book["marketId"]]
        next unless metadata

        # 1. Get the Rich Data (Spread, Volume, Prices)
        rich_runner_data = parse_runners_extended(book["runners"], metadata[:runners])

        # 2. Get the Percentages (Implied Probability)
        # We assume this returns an array of hashes with at least { selection_id: ..., percentage: ... }
        probability_data = ProbabilityCalculator.to_percentages(rich_runner_data)

        # 3. MERGE THEM! 
        # We map the percentage back onto the rich data using selection_id as the key
        probs_map = probability_data.index_by { |p| p[:selection_id] }

        final_runners = rich_runner_data.map do |runner|
          # Merge the calculated percentage into the rich runner hash
          runner.merge(
            percentage: probs_map.dig(runner[:selection_id], :percentage)
          )
        end

        {
          event_name: metadata[:event_name],
          betfair_event_id: metadata[:betfair_event_id],
          market_name: metadata[:market_name],
          kick_off: metadata[:kick_off],
          market_id: book["marketId"],
          betfair_competition_id: betfair_competition_id,
          status: book["status"],
          inplay: book["inplay"],
          total_matched: book["totalMatched"],
          total_available: book["totalAvailable"],
          
          # Now this contains EVERYTHING: spread, total_matched, AND percentage
          runners: final_runners 
        }
      end.compact

      all_matches.concat(chunk_matches)
    end

    if persist && all_matches.any?
      BetfairSnapshotPersister.new(matches: all_matches).persist!
    end

    all_matches
  end

  def list_match_odds_markets(event_ids)
    payload = {
      filter: {
        eventIds: Array(event_ids),
        marketTypeCodes: ["MATCH_ODDS"]
      },
      maxResults: 100, # Increased to ensure we catch all markets in the chunk
      marketProjection: ["RUNNER_DESCRIPTION", "EVENT"]
    }
    post_request("listMarketCatalogue/", payload)
  end

  private

  def get_market_prices_batch(market_ids)
    return [] if market_ids.empty?
    payload = {
      marketIds: market_ids,
      priceProjection: { priceData: ["EX_BEST_OFFERS"] }
    }
    post_request("listMarketBook/", payload)
  end

  def parse_runners_extended(runners_data, runner_name_map)
    runners_data.map do |runner|
      back_price = runner.dig("ex", "availableToBack", 0, "price")
      lay_price = runner.dig("ex", "availableToLay", 0, "price")
      
      spread = (lay_price && back_price) ? (lay_price - back_price).round(2) : nil

      {
        name: runner_name_map[runner["selectionId"]],
        selection_id: runner["selectionId"],
        back_price: back_price,
        lay_price: lay_price,
        spread: spread,
        
        # FIX: Add || 0.0 here to prevent nils in your database
        total_matched: runner["totalMatched"] || 0.0,      
        last_price_traded: runner["lastPriceTraded"]
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
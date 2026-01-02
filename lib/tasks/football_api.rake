namespace :football_api do
  desc "Fetch and summarize upcoming and recent Premier League matches"
  task sync_matches: :environment do
    api = FootballApiService.new

    puts "--- Fetching Premier League Matches ---"

    result = api.sync_matches

    unless result[:success]
      puts "Error while syncing matches: #{result[:error]}"
      return
    end

    puts "----------------------------------------------------"
    puts "Total matches found: #{result[:total_matches]}"
    puts "Events updated: #{result[:updated_events]}"
    puts "Events skipped: #{result[:skipped_events]}"

    if result[:unmatched_fixtures].present?
      puts "Unmatched fixture IDs: #{result[:unmatched_fixtures].join(', ')}"
    end
  end

  desc "Search API-Football league IDs for competitions defined in db/seeds/competitions.yml"
  task find_league_ids: :environment do
    season = (ENV["SEASON"] || "2025").to_i

    yml_path = Rails.root.join("db/seeds/competitions.yml")
    unless File.exist?(yml_path)
      abort "Missing YAML file: #{yml_path}"
    end

    competitions = YAML.load_file(yml_path)
    competitions = Array(competitions)
    countries = competitions.map { |comp| comp["api_football_country"] }.compact.uniq


    api = FootballApiService.new(season: season)

    puts "--- Searching for league IDs for season #{season} ---"

    countries.each_with_index do |country, idx|
      country_name = country.to_s.strip

      response = response = api.search_leagues(country: country, season: 2025)

      leagues = response['response'].map { |l| [l['league']['id'], l['league']['name']] }
      puts "\nLeagues for country '#{country_name}': #{leagues}"
    end
  end
end

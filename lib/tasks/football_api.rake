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
end

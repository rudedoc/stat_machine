# lib/tasks/sportmonks.rake
namespace :sportmonks do
  desc "Sync all fixtures and predictions for the next 7 days"
  task sync_week: :environment do
    client = SportmonksClient.new
    # Define the range: Today through 7 days from now
    date_range = Date.today..(Date.today + 7.days)

    puts "=== Starting Full Week Sync: #{date_range.first} to #{date_range.last} ==="

    date_range.each do |date|
      sync_date = date.to_s
      current_page = 1
      daily_total = 0

      puts "\n--- Processing Date: #{sync_date} ---"

      loop do
        response = client.get_fixtures_by_date(
          sync_date,
          includes: ['participants', 'league.country', 'predictions'],
          page: current_page
        )

        fixtures = response['data'] || []
        pagination = response['pagination']

        fixtures.each do |fixture_json|
          SyncFixtureService.call(fixture_json)
          daily_total += 1
        end

        print "." # Visual indicator of progress per page

        if pagination && pagination['has_more']
          current_page += 1
          # Optional: Small sleep to be kind to the API rate limit
          sleep 0.05
        else
          break
        end
      end

      puts "\nFinished #{sync_date}: Synced #{daily_total} fixtures."
    end

    puts "\n=== 1-Week Sync Complete ==="
  end
end

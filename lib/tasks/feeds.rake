# lib/tasks/feeds.rake
namespace :feeds do
  desc "Fetch and import latest entries from all active feed sources"
  task import_all: :environment do
    puts "Starting global feed import..."
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    # Iterate over all sources
    FeedSource.find_each do |source|
      begin
        puts "Importing feed: #{source.name} (#{source.feed_url})"
        FeedImporter.new(source).call
      rescue StandardError => e
        # Ensure one failing feed doesn't crash the entire batch
        puts "ERROR importing #{source.name}: #{e.message}"
        Rails.logger.error("Feed Import Task Error [#{source.name}]: #{e.message}")
      end
    end
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
    puts "Global import complete in #{format('%.2f', elapsed)}s."
  end

  desc "Import a specific feed by ID (Usage: rake feeds:import_one[1])"
  task import_one: :environment do |t, args|
    source = FeedSource.find_by(id: 1)

    if source
      FeedImporter.new(source).call
    else
      puts "FeedSource with ID #{args[:feed_source_id]} not found."
    end
  end
end

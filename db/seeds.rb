require "csv"

feed_sources_path = Rails.root.join("db", "rss_feeds.csv")

if File.exist?(feed_sources_path)
  CSV.foreach(feed_sources_path, headers: true) do |row|
    name = row["Source Name"].to_s.strip
    feed_url = row["Feed URL"].to_s.strip
    next if name.blank? || feed_url.blank?

    FeedSource.find_or_initialize_by(feed_url: feed_url).tap do |feed|
      feed.name = name
      feed.save!
    end
  end
end

BetfairApi.import_all_data!

FootballApiService.new.sync_matches

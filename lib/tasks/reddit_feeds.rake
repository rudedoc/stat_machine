# frozen_string_literal: true

namespace :reddit do
  desc "Fetch and normalize Reddit Atom feeds. Usage: rake reddit:fetch_feeds FEED=https://www.reddit.com/r/soccer/.rss LIMIT=10 OUT=tmp/soccer.json"
  task fetch_feeds: :environment do
    urls = ["https://www.reddit.com/r/soccer/.rss"]
    out_path = ENV["OUT"]

    results = []

    urls.each do |url|
      puts "Fetching: #{url}"
      feed = RssFetcher.new(url).call
      entries = feed.entries
      normalized = entries.map { |entry| RedditAtomNormalizer.normalize(entry) }

      puts "  Parsed #{entries.size} entries; normalized #{normalized.size}"
      normalized.each_with_index do |e, i|
        puts format("  %2d. %s (%s)", i + 1, e[:title].to_s.tr("\n", " "), e[:published_at])
      end

      results << { url: url, fetched_at: Time.zone.now, entries: normalized }
    end

    if out_path.present?
      require "json"
      FileUtils.mkdir_p(File.dirname(out_path))
      File.write(out_path, JSON.pretty_generate(results))
      puts "Wrote JSON: #{out_path}"
    end

    puts "Done."
  rescue RssFetcher::FetchError, RssFetcher::ParseError => e
    warn "RSS error: #{e.message}"
    exit(1)
  rescue StandardError => e
    warn "Unexpected error: #{e.class}: #{e.message}"
    warn e.backtrace.take(10).join("\n")
    exit(1)
  end
end

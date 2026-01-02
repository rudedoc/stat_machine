require "csv"
require "yaml"

# db/seeds.rb

def normalize_alias_list(values)
  Array(values).map { |value| value.to_s.downcase.gsub(/\s+/, " ").strip }
               .reject(&:blank?).uniq
end

def normalized_aliases_for(team_data)
  betfair_names = normalize_alias_list(team_data[:betfair_names])
  manual_aliases = normalize_alias_list(team_data[:aliases])

  (betfair_names + manual_aliases).uniq
end

teams_path = Rails.root.join("db/seeds/teams.yml")
teams_data = Array(YAML.load_file(teams_path)).map { |h| h.deep_symbolize_keys }

puts "Seeding Teams..."

teams_data.each do |team_data|
  alias_values = normalized_aliases_for(team_data)

  # We match on name and category to prevent duplicates
  tag = Tag.find_or_initialize_by(name: team_data[:name], category: 'team')

  # Ensure we don't overwrite existing aliases if you added custom ones manually later
  # But for initial seed, we can just set them.
  tag.aliases = (Array(tag.aliases) + alias_values).uniq

  if tag.save
    tag.merge_duplicate_alias_records!
    print "."
  else
    puts "\nFailed to save #{team_data[:name]}: #{tag.errors.full_messages.join(', ')}"
  end
end

puts "\nDone! #{Tag.teams.count} teams seeded."

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

require "yaml"

competitions_path = Rails.root.join("db/seeds/competitions.yml")
competitions = YAML.load_file(competitions_path)

competitions.each do |attrs|
  comp = Competition.find_or_initialize_by(betfair_id: attrs["betfair_id"])
  comp.assign_attributes(
    name: attrs["name"],
    competition_region: attrs["competition_region"],
    country_code: attrs["country_code"],
    football_api_league_id: attrs["football_api_league_id"] # will be nil until you populate it
  )
  comp.synced_at ||= Time.current
  comp.save!
end

puts "Seeding Feed Sources done! #{FeedSource.count} sources seeded."

# BetfairApi.import_all_data!

# puts "Synchronizing matches from Football API..."

# FootballApiService.new.sync_matches

# # call rake feeds:import_all task to import feeds after seeding
# Rake::Task["feeds:import_all"].invoke

# puts "Seeding complete."

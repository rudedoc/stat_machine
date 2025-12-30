require "csv"

# db/seeds.rb

teams_data = [
  {
    name: "Arsenal",
    aliases: ["arsenal", "gunners", "gooners", "ars", "afc"]
  },
  {
    name: "Aston Villa",
    aliases: ["villa", "avfc", "villans", "claret and blue"]
  },
  {
    name: "Bournemouth",
    aliases: ["cherries", "afcb", "boscombe"]
  },
  {
    name: "Brentford",
    aliases: ["bees", "brentford fc"]
  },
  {
    name: "Brighton & Hove Albion",
    aliases: ["brighton", "seagulls", "bha", "bhafc", "albion"]
  },
  {
    name: "Burnley",
    aliases: ["clarets", "bfc", "turf moor"]
  },
  {
    name: "Chelsea",
    aliases: ["blues", "cfc", "chelsea fc", "che", "pensioners"]
  },
  {
    name: "Crystal Palace",
    aliases: ["palace", "cpfc", "eagles", "selhurst"]
  },
  {
    name: "Everton",
    aliases: ["toffees", "efc", "blues", "school of science"]
  },
  {
    name: "Fulham",
    aliases: ["cottagers", "ffc", "whites"]
  },
  {
    name: "Leeds United",
    aliases: ["Leeds", "lufc", "whites", "peacocks", "elland road"]
  },
  {
    name: "Leicester City",
    aliases: ["Leicester", "foxes", "lcfc", "lei"]
  },
  {
    name: "Liverpool",
    aliases: ["reds", "lfc", "kop", "pool", "liv"]
  },
  {
    name: "Manchester City",
    aliases: ["Man City", "city", "mcfc", "citizens", "sky blues", "pep"]
  },
  {
    name: "Manchester United",
    aliases: ["Man Utd", "man u", "united", "mufc", "red devils", "man united", "ten hag"]
  },
  {
    name: "Newcastle United",
    aliases: ["Newcastle", "nufc", "magpies", "toon", "geordies", "new"]
  },
  {
    name: "Nottingham Forest",
    aliases: ["Nottm Forest", "forest", "nffc", "tricky trees", "reds"]
  },
  {
    name: "Sheffield United",
    aliases: ["Sheff Utd", "blades", "sufc"]
  },
  {
    name: "Southampton",
    aliases: ["saints", "sfc"]
  },
  {
    name: "Sunderland",
    aliases: ["black cats", "safc", "mackems"]
  },
  {
    name: "Tottenham Hotspur",
    aliases: ["spurs", "thfc", "tottenham", "lilywhites", "tot"]
  },
  {
    name: "West Ham United",
    aliases: ["West Ham", "hammers", "whufc", "irons", "whu"]
  },
  {
    name: "Wolverhampton Wanderers",
    aliases: ["wolves", "wwfc", "wanderers"]
  }
]

puts "Seeding Teams..."

teams_data.each do |team_data|
  # We match on name and category to prevent duplicates
  tag = Tag.find_or_initialize_by(name: team_data[:name], category: 'team')

  # Ensure we don't overwrite existing aliases if you added custom ones manually later
  # But for initial seed, we can just set them.
  tag.aliases = (Array(tag.aliases) + team_data[:aliases]).uniq

  if tag.save
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

puts "Seeding Feed Sources done! #{FeedSource.count} sources seeded."

BetfairApi.import_all_data!

puts "Synchronizing matches from Football API..."

FootballApiService.new.sync_matches

# call rake feeds:import_all task to import feeds after seeding
Rake::Task["feeds:import_all"].invoke

puts "Seeding complete."

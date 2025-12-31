require "csv"

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

teams_data = [
  {
    name: "Arsenal",
    betfair_names: [],
    aliases: ["gunners", "gooners", "ars", "afc"]
  },
  {
    name: "Aston Villa",
    betfair_names: [],
    aliases: ["villa", "avfc", "villans", "claret and blue"]
  },
  {
    name: "Bournemouth",
    betfair_names: ["afc bournemouth"],
    aliases: ["cherries", "afcb", "boscombe"]
  },
  {
    name: "Brentford",
    betfair_names: [],
    aliases: ["bees", "brentford fc"]
  },
  {
    name: "Brighton & Hove Albion",
    betfair_names: ["brighton", "brighton and hove albion"],
    aliases: ["seagulls", "bha", "bhafc", "albion"]
  },
  {
    name: "Burnley",
    betfair_names: [],
    aliases: ["clarets", "bfc", "turf moor"]
  },
  {
    name: "Chelsea",
    betfair_names: [],
    aliases: ["blues", "cfc", "chelsea fc", "che", "pensioners"]
  },
  {
    name: "Crystal Palace",
    betfair_names: [],
    aliases: ["palace", "cpfc", "eagles", "selhurst"]
  },
  {
    name: "Everton",
    betfair_names: [],
    aliases: ["toffees", "efc", "blues", "school of science"]
  },
  {
    name: "Fulham",
    betfair_names: [],
    aliases: ["cottagers", "ffc", "whites"]
  },
  {
    name: "Leeds United",
    betfair_names: ["leeds", "leeds utd"],
    aliases: ["lufc", "whites", "peacocks", "elland road"]
  },
  {
    name: "Leicester City",
    betfair_names: ["leicester"],
    aliases: ["foxes", "lcfc", "lei"]
  },
  {
    name: "Liverpool",
    betfair_names: [],
    aliases: ["reds", "lfc", "kop", "pool", "liv"]
  },
  {
    name: "Manchester City",
    betfair_names: ["man city"],
    aliases: ["city", "mcfc", "citizens", "sky blues", "pep"]
  },
  {
    name: "Manchester United",
    betfair_names: ["man utd", "man u", "man united"],
    aliases: ["united", "mufc", "red devils", "ten hag"]
  },
  {
    name: "Newcastle United",
    betfair_names: ["newcastle"],
    aliases: ["nufc", "magpies", "toon", "geordies", "new"]
  },
  {
    name: "Nottingham Forest",
    betfair_names: ["nottm forest"],
    aliases: ["forest", "nffc", "tricky trees", "reds"]
  },
  {
    name: "Sheffield United",
    betfair_names: ["sheff utd"],
    aliases: ["blades", "sufc"]
  },
  {
    name: "Southampton",
    betfair_names: [],
    aliases: ["saints", "sfc"]
  },
  {
    name: "Sunderland",
    betfair_names: [],
    aliases: ["black cats", "safc", "mackems"]
  },
  {
    name: "Tottenham Hotspur",
    betfair_names: ["tottenham", "spurs"],
    aliases: ["thfc", "lilywhites", "tot"]
  },
  {
    name: "West Ham United",
    betfair_names: ["west ham"],
    aliases: ["hammers", "whufc", "irons", "whu"]
  },
  {
    name: "Wolverhampton Wanderers",
    betfair_names: ["wolves", "wolverhampton"],
    aliases: ["wwfc", "wanderers"]
  }
]

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

puts "Seeding Feed Sources done! #{FeedSource.count} sources seeded."

BetfairApi.import_all_data!

puts "Synchronizing matches from Football API..."

FootballApiService.new.sync_matches

# call rake feeds:import_all task to import feeds after seeding
Rake::Task["feeds:import_all"].invoke

puts "Seeding complete."

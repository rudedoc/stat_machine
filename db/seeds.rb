BetfairApi.import_all_data!

FootballApiService.new.sync_matches


puts "🌱 Seeding Teams and Aliases..."

teams_data = [
  {
    name: "Arsenal",
    short_name: "Arsenal",
    betfair_name: "Arsenal",
    aliases: ["gunners", "gooners", "ars", "afc"]
  },
  {
    name: "Aston Villa",
    short_name: "Aston Villa",
    betfair_name: "Aston Villa",
    aliases: ["villa", "avfc", "villans", "claret and blue"]
  },
  {
    name: "Bournemouth",
    short_name: "Bournemouth",
    betfair_name: "Bournemouth",
    aliases: ["cherries", "afcb", "boscombe"]
  },
  {
    name: "Brentford",
    short_name: "Brentford",
    betfair_name: "Brentford",
    aliases: ["bees", "brentford fc"]
  },
  {
    name: "Brighton & Hove Albion",
    short_name: "Brighton",
    betfair_name: "Brighton",
    aliases: ["seagulls", "bha", "bhafc", "albion"]
  },
  {
    name: "Burnley",
    short_name: "Burnley",
    betfair_name: "Burnley",
    aliases: ["clarets", "bfc", "turf moor"]
  },
  {
    name: "Chelsea",
    short_name: "Chelsea",
    betfair_name: "Chelsea",
    aliases: ["blues", "cfc", "chelsea fc", "che", "pensioners"]
  },
  {
    name: "Crystal Palace",
    short_name: "Crystal Palace",
    betfair_name: "Crystal Palace",
    aliases: ["palace", "cpfc", "eagles", "selhurst"]
  },
  {
    name: "Everton",
    short_name: "Everton",
    betfair_name: "Everton",
    aliases: ["toffees", "efc", "blues", "school of science"]
  },
  {
    name: "Fulham",
    short_name: "Fulham",
    betfair_name: "Fulham",
    aliases: ["cottagers", "ffc", "whites"]
  },
  {
    name: "Leeds United",
    short_name: "Leeds",
    betfair_name: "Leeds",
    aliases: ["lufc", "whites", "peacocks", "elland road"]
  },
  {
    name: "Leicester City",
    short_name: "Leicester",
    betfair_name: "Leicester",
    aliases: ["foxes", "lcfc", "lei"]
  },
  {
    name: "Liverpool",
    short_name: "Liverpool",
    betfair_name: "Liverpool",
    aliases: ["reds", "lfc", "kop", "pool", "liv"]
  },
  {
    name: "Manchester City",
    short_name: "Man City",
    betfair_name: "Man City",
    aliases: ["city", "mcfc", "citizens", "sky blues", "pep"]
  },
  {
    name: "Manchester United",
    short_name: "Man Utd",
    betfair_name: "Man Utd",
    aliases: ["man u", "united", "mufc", "red devils", "man united", "ten hag"]
  },
  {
    name: "Newcastle United",
    short_name: "Newcastle",
    betfair_name: "Newcastle",
    aliases: ["nufc", "magpies", "toon", "geordies", "new"]
  },
  {
    name: "Nottingham Forest",
    short_name: "Nottm Forest",
    betfair_name: "Nottm Forest", # Critical Betfair mapping
    aliases: ["forest", "nffc", "tricky trees", "reds"]
  },
  {
    name: "Sheffield United",
    short_name: "Sheff Utd",
    betfair_name: "Sheff Utd",
    aliases: ["blades", "sufc"]
  },
  {
    name: "Southampton",
    short_name: "Southampton",
    betfair_name: "Southampton",
    aliases: ["saints", "sfc"]
  },
  {
    name: "Sunderland",
    short_name: "Sunderland",
    betfair_name: "Sunderland",
    aliases: ["black cats", "safc", "mackems"]
  },
  {
    name: "Tottenham Hotspur",
    short_name: "Spurs",
    betfair_name: "Tottenham",
    aliases: ["spurs", "thfc", "tottenham", "lilywhites", "tot"]
  },
  {
    name: "West Ham United",
    short_name: "West Ham",
    betfair_name: "West Ham",
    aliases: ["hammers", "whufc", "irons", "whu"]
  },
  {
    name: "Wolverhampton Wanderers",
    short_name: "Wolves",
    betfair_name: "Wolves",
    aliases: ["wolves", "wwfc", "wanderers"]
  }
]

teams_data.each do |data|
  # We use find_or_initialize to avoid duplicates if you run seeds multiple times
  team = Team.find_or_initialize_by(name: data[:name])
  
  team.assign_attributes(
    short_name: data[:short_name],
    betfair_name: data[:betfair_name],
    # Ensure aliases are always lowercase for easy matching
    aliases: data[:aliases].map(&:downcase)
  )

  if team.save
    print "."
  else
    puts "\n❌ Failed to save #{data[:name]}: #{team.errors.full_messages.join(', ')}"
  end
end

puts "\n✅ Seed complete! Created/Updated #{Team.count} teams."
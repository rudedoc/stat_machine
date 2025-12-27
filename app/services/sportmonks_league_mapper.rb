# app/services/sportmonks_league_mapper.rb
class SportmonksLeagueMapper
  # Hardcode the big ones to ensure 100% accuracy
  MAJOR_LEAGUE_MAP = {
    "English Premier League" => 8,
    "English Sky Bet Championship" => 9,
    "English Sky Bet League 1" => 12,
    "English Sky Bet League 2" => 14,
    "English National League" => 17,
    "Scottish Premiership" => 501,
    "Spanish La Liga" => 564,
    "Italian Serie A" => 384,
    "Italian Serie B" => 387,
    "French Ligue 1" => 301,
    "Belgian Pro League" => 208,
    "Portuguese Primeira Liga" => 462,
    "Saudi Professional League" => 995,
    "Turkish 1 Lig" => 600,
    "Israeli Premier League" => 456
  }.freeze

  def self.map_all!
    client = SportmonksClient.new
    # Ensure you use the paginated fetch_country_map we discussed
    countries = client.fetch_country_map

    Competition.where(sportmonks_league_id: nil).find_each do |comp|
      # 1. Check Hardcoded Map First
      if (manual_id = MAJOR_LEAGUE_MAP[comp.name])
        comp.update(sportmonks_league_id: manual_id)
        puts "✅ Manual Match: #{comp.name} -> #{manual_id}"
        next
      end

      # 2. Determine Correct Country ID
      country_id = determine_country_id(comp, countries)

      # 3. Search with a "Light" Clean
      query = comp.name.gsub(/English |Scottish |Sky Bet /i, '').strip

      response = client.get_data("/leagues/search/#{URI.encode_www_form_component(query)}")
      results = response&.dig('data') || []

      # 4. Match within the specific country
      match = results.find { |r| r['country_id'] == country_id }

      if match
        comp.update(sportmonks_league_id: match['id'])
        puts "✅ Search Match: #{comp.name} -> #{match['id']}"
      else
        puts "❌ No match: '#{query}' in Country #{country_id}"
      end
    end
  end

  def self.determine_country_id(comp, countries)
    return 1161 if comp.name.include?("Scottish")
    return 462  if comp.country_code == "GB" # Default GB to England
    countries[comp.country_code]
  end
end

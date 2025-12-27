# app/services/sportmonks_client.rb
class SportmonksClient
  BASE_URL = 'https://api.sportmonks.com/v3/football'

  def initialize
    @api_token = Rails.application.credentials.dig(:sportmonks, :api_token)
  end

  def get_fixtures_by_date(date, includes: [])
    query = { api_token: @api_token }
    query[:include] = includes.join(';') if includes.any?

    response = Faraday.get("#{BASE_URL}/fixtures/date/#{date}", query)
    JSON.parse(response.body)
  end

  def get_league_standings(season_id)
    response = Faraday.get("#{BASE_URL}/standings/seasons/#{season_id}", { api_token: @api_token })
    JSON.parse(response.body)
  end
end

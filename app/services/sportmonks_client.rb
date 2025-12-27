# app/services/sportmonks_client.rb
class SportmonksClient
  include HTTParty
  base_uri 'https://api.sportmonks.com/v3/football'

  def initialize
    @options = {
      query: { api_token: Rails.application.credentials.dig(:sportmonks, :api_token) },
      headers: { 'Accept' => 'application/json' }
    }
  end

  # Generic GET method
  def get_data(endpoint, params = {})
    query_params = @options[:query].merge(params)
    self.class.get(endpoint, @options.merge(query: query_params))
  end

  # Example: Fetch all teams with optional pagination and includes
  def teams(page: 1, includes: nil)
    params = { page: page }
    params[:include] = includes if includes
    get_data('/teams', params)
  end
end

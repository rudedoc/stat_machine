# app/services/sportmonks_client.rb
require 'cgi'

class SportmonksClient
  include HTTParty
  # Move the base to the root of the API
  base_uri 'https://api.sportmonks.com/v3'

  def initialize
    @api_token = Rails.application.credentials.dig(:sportmonks, :api_token)
  end

  def all_leagues(page: 1)
    get_data("/leagues", { page: page, per_page: 50 })
  end

  # To loop through every league in your plan:
  def fetch_all_subscribed_leagues
    all_leagues = []
    page = 1

    loop do
      response = all_leagues(page: page)
      break unless response && response['data']&.any?

      all_leagues += response['data']

      break unless response.dig('pagination', 'has_more')
      page += 1
    end

    all_leagues
  end

  # app/services/sportmonks_client.rb
  def fetch_country_map
    all_countries = {}
    page = 1

    loop do
      response = get_data("/core/countries", { page: page })
      break unless response && response['data']&.any?

      response['data'].each do |country|
        # Note: Use iso2 (e.g., 'GB') as the key
        code = country['iso2']
        all_countries[code] = country['id'] if code
      end

      # Check if there is a next page
      pagination = response['pagination']
      break unless pagination && pagination['has_more']
      page += 1
    end

    all_countries
  end

  def get_data(endpoint, params = {})
    # 1. Clean up the endpoint to remove leading slashes
    endpoint = endpoint.delete_prefix('/')

    # 2. Decide the namespace (Core vs Football)
    namespace = endpoint.start_with?('core', 'my') ? "" : "football/"

    # 3. Build the path WITHOUT repeating /v3
    # Since base_uri already has /v3, we start the path from the namespace
    path = "/#{namespace}#{endpoint}"

    options = {
      query: params.merge(api_token: @api_token),
      headers: { 'Accept' => 'application/json' }
    }

    # Log the actual URL we are about to hit for debugging
    # puts "Requesting: #{self.class.base_uri}#{path}"

    response = self.class.get(path, options)

    if response.success?
      JSON.parse(response.body)
    else
      # Log the full failed path for better debugging
      Rails.logger.error "Sportmonks API Error [#{response.code}] on #{path}: #{response.body}"
      nil
    end
  end
end

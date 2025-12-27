# app/controllers/countries_controller.rb
class CountriesController < ApplicationController
  def index
    # Only show countries that actually have leagues in our DB
    @countries = Country.joins(:leagues).distinct.order(:name)
  end

  def show
    @country = Country.find(params[:id])
    @leagues = @country.leagues.where(active: true)
  end
end

# app/controllers/leagues_controller.rb
class LeaguesController < ApplicationController
  def show
    @league = League.find(params[:id])
    # Show fixtures for the current season
    @season = @league.seasons.find_by(is_current: true)
    @fixtures = @season.fixtures.upcoming.limit(20)
  end
end

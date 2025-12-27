# app/controllers/leagues_controller.rb
class LeaguesController < ApplicationController
  def show
    @league = League.find(params[:id])
    # Show fixtures for the current season
    @season = @league.seasons.find_by(is_current: true)
    @fixtures = @season.fixtures.upcoming.limit(20)
  end
end

# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  def home
    api = BetfairApi.new

    if params[:country].present? && params[:competition_id].present?
      # Stage 3: Show matches for specific league
      @matches = api.fetch_match_odds_by_competition(params[:competition_id])
    elsif params[:country].present?
      # Stage 2: Show leagues in selected country
      @competitions = api.list_competitions([params[:country]])
    else
      # Stage 1: Show country choices
      @countries = api.list_countries
    end
  end
end

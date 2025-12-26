class PagesController < ApplicationController
  def home
    @matches = BetfairApi.fetch_soccer_odds
  end
end

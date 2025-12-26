# app/controllers/api/v1/competitions_controller.rb
class Api::V1::CompetitionsController < ActionController::API
  def index
    competitions = BetfairApi.new.list_competitions([params[:country_id]])
    render json: competitions
  end
end

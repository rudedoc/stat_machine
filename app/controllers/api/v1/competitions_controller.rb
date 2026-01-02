# app/controllers/api/v1/competitions_controller.rb
class Api::V1::CompetitionsController < Api::V1::BaseController
  def index
    country_code = params[:country_id].presence
    country = Country.find_by!(country_code: country_code)
    competitions = country.competitions.ordered_by_position
    render json: competitions
  end
end

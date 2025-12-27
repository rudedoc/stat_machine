# app/controllers/api/v1/competitions_controller.rb
class Api::V1::CompetitionsController < Api::V1::BaseController
  def index
    country_code = params[:country_id].presence
    competitions = if country_code.present?
                     Competition.ensure_synced_for_country!(country_code)
                   else
                     Competition.none
                   end
    render json: competitions
  end
end

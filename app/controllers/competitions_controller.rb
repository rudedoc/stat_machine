# app/controllers/competitions_controller.rb
class CompetitionsController < ApplicationController
  before_action :set_country

  def index
    @competitions = @country.competitions.includes(:events).ordered_by_position
  end

  private

  def set_country
    code = params[:country_country_code] || params[:country_id]
    @country = Country.find_by!(country_code: code)
  end
end

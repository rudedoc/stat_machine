# app/controllers/api/v1/countries_controller.rb
class Api::V1::CountriesController < Api::V1::BaseController
  def index
    @countries = BetfairApi.new.list_countries
    render json: @countries
  end
end

# app/controllers/countries_controller.rb
class CountriesController < ApplicationController
  def index
    @countries = Country.all.order(:position).includes(competitions: :events)
  end
end

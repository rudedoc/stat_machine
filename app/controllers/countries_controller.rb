# app/controllers/countries_controller.rb
class CountriesController < ApplicationController
  def index
    @countries = Country.all.includes(competitions: :events)
  end
end

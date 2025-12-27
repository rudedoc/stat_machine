# app/controllers/countries_controller.rb
class CountriesController < ApplicationController
  def index
    @countries = Country.ensure_synced!.includes(:events)
  end
end

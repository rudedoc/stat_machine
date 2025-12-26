# app/controllers/api/v1/base_controller.rb
class Api::V1::BaseController < ActionController::API
  # This class inherits from ActionController::API to keep it lightweight
  # as it doesn't need CSRF protection or Flash messages.
end

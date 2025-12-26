# app/controllers/api/v1/base_controller.rb
class Api::V1::BaseController < ActionController::API
  # This class inherits from ActionController::API to keep it lightweight
  # as it doesn't need CSRF protection or Flash messages.
  def authenticate_firebase_user
    auth_header = request.headers['Authorization']
    token = auth_header&.split(' ')&.last

    @firebase_user = FirebaseAuthService.verify(token)

    # CRITICAL: Stop the request here if verification fails
    if @firebase_user.nil?
      render json: { error: 'Unauthorized', message: 'Invalid or expired token' }, status: :unauthorized
    end
  end

  def current_user
    @firebase_user
  end
end

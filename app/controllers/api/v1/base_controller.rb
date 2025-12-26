# app/controllers/api/v1/base_controller.rb
class Api::V1::BaseController < ActionController::API
  # This class inherits from ActionController::API to keep it lightweight
  # as it doesn't need CSRF protection or Flash messages.
  def authenticate_firebase_user
    auth_header = request.headers['Authorization']
    token = auth_header&.split(' ')&.last

    @firebase_user = FirebaseAuthService.verify(token)

    # CRITICAL: Stop the request here if verification fails
    return if @firebase_user.present?

    render json: { error: 'Unauthorized', message: 'Invalid or expired token' }, status: :unauthorized and return
  end

  def current_user
    return @current_user if defined?(@current_user)
    return if @firebase_user.blank?

    @current_user = User.from_firebase(@firebase_user)
    @current_user.save! if @current_user.changed?
    @current_user
  end
end

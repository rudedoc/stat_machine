# app/controllers/api/v1/profiles_controller.rb
class Api::V1::ProfilesController < Api::V1::BaseController
  before_action :authenticate_firebase_user

  def show
    user = current_user

    render json: {
      uid: user.firebase_uid,
      email: user.email,
      name: user.display_name,
      picture: user.photo_url,
      authenticated_at: user.last_authenticated_at,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end
end

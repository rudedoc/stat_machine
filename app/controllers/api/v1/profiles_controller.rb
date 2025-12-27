# app/controllers/api/v1/profiles_controller.rb
class Api::V1::ProfilesController < Api::V1::BaseController
  before_action :authenticate_firebase_user

  def show
    render json: serialized_user(current_user)
  end

  def update
    user = current_user

    if user.update(profile_params)
      render json: serialized_user(user)
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:profile).permit(:display_name, :photo_url)
  end

  def serialized_user(user)
    {
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

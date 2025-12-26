# app/controllers/api/v1/profiles_controller.rb
class Api::V1::ProfilesController < Api::V1::BaseController
  def show
    # The @firebase_user is already set by the authenticate_firebase_user
    # before_action in your BaseController.

    authenticate_firebase_user

    puts "Firebase User Info: #{@firebase_user.inspect}"

    render json: {
      uid: @firebase_user['sub'],
      email: @firebase_user['email'],
      name: @firebase_user['name'],
      picture: @firebase_user['picture'],
      authenticated_at: Time.at(@firebase_user['auth_time'])
    }
  end
end

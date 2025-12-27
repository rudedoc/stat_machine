class User < ApplicationRecord
  before_validation :normalize_email

  validates :firebase_uid, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :display_name, length: { maximum: 120 }, allow_blank: true

  class << self
    # Build or update a user record based on Firebase payload data.
    def from_firebase(payload)
      uid = payload['sub'] || payload['user_id']
      raise ArgumentError, 'Missing Firebase UID' unless uid.present?

      user = find_or_initialize_by(firebase_uid: uid)
      user.email = payload['email'] if payload['email'].present?
      user.display_name = payload['name'] || payload['display_name']
      user.photo_url = payload['picture'] if payload['picture'].present?

      auth_time = payload['auth_time']
      if auth_time.present?
        seconds = auth_time.is_a?(Numeric) ? auth_time : auth_time.to_i
        time_value = Time.zone ? Time.zone.at(seconds) : Time.at(seconds)
        user.last_authenticated_at = time_value
      end

      user
    end
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end
end

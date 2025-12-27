# app/models/prediction.rb
class Prediction < ApplicationRecord
  self.inheritance_column = :_type_disabled

  belongs_to :fixture

  validates :external_id, presence: true, uniqueness: true

  # Example helper to find the win probability specifically
  def self.fulltime_result
    find_by(type_id: 237)
  end
end

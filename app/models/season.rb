# app/models/season.rb
class Season < ApplicationRecord
  belongs_to :league
  has_many :fixtures, dependent: :destroy

  validates :external_id, presence: true, uniqueness: true

  scope :current, -> { where(is_current: true) }
end

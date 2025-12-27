# app/models/price.rb
class Price < ApplicationRecord
  belongs_to :fixture
  belongs_to :market
  belongs_to :bookmaker

  validates :external_id, presence: true, uniqueness: true

  # Handy for fans: "What is the most likely outcome?"
  scope :most_probable, -> { order(probability: :desc) }

  # Filter by specific bookmaker (e.g., Bet365 is ID 2)
  scope :from_bookmaker, ->(id) { where(bookmaker_id: id) }
end

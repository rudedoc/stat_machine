# app/models/market.rb
class Market < ApplicationRecord
  has_many :prices, dependent: :destroy # We will call these 'Prices' as you requested

  validates :external_id, presence: true, uniqueness: true
  validates :name, presence: true

  # Useful helper for your reporting
  scope :with_settlement, -> { where(has_winning_calculations: true) }
end

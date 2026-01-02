# frozen_string_literal: true

class Competitor < ApplicationRecord
  belongs_to :market
  has_many :prices, -> { order(captured_at: :desc) }, dependent: :destroy
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings

  validates :selection_id, presence: true, uniqueness: { scope: :market_id }
  validates :name, presence: true

  def latest_price
    prices.first
  end

  def latest_percentage
    latest_price&.percentage&.to_f
  end

  def recent_prices(limit = 3)
    prices.limit(limit)
  end
end

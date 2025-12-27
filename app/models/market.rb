# frozen_string_literal: true

class Market < ApplicationRecord
  belongs_to :event
  has_many :competitors, dependent: :destroy

  validates :betfair_market_id, presence: true, uniqueness: true
  validates :name, presence: true

  def latest_probabilities
    competitors.map do |competitor|
      percentage = competitor.latest_percentage
      next unless percentage

      { name: competitor.name, percentage: percentage }
    end.compact
  end

  def last_synced_label
    (last_synced_at || updated_at)&.in_time_zone
  end
end

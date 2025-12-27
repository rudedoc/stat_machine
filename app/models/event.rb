# frozen_string_literal: true

class Event < ApplicationRecord
  belongs_to :competition, primary_key: :betfair_id, foreign_key: :betfair_competition_id, optional: true
  has_many :markets, dependent: :destroy
  has_many :competitors, through: :markets

  validates :betfair_event_id, presence: true, uniqueness: true
  validates :betfair_competition_id, :name, :kick_off, presence: true

  def primary_market
    markets.max_by { |market| market.last_synced_at || market.updated_at }
  end

  def to_param
    betfair_event_id
  end
end

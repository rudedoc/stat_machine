# frozen_string_literal: true

class Event < ApplicationRecord
  has_many :markets, dependent: :destroy

  validates :betfair_event_id, presence: true, uniqueness: true
  validates :betfair_competition_id, :name, :kick_off, presence: true
end

# frozen_string_literal: true

class Market < ApplicationRecord
  belongs_to :event
  has_many :competitors, dependent: :destroy

  validates :betfair_market_id, presence: true, uniqueness: true
  validates :name, presence: true
end

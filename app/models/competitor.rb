# frozen_string_literal: true

class Competitor < ApplicationRecord
  belongs_to :market
  has_many :prices, dependent: :destroy

  validates :selection_id, presence: true, uniqueness: { scope: :market_id }
  validates :name, presence: true
end

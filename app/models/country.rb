# frozen_string_literal: true

class Country < ApplicationRecord
  REFRESH_INTERVAL = 60.minutes

  has_many :competitions, primary_key: :country_code, foreign_key: :country_code
  has_many :events, through: :competitions

  validates :country_code, presence: true, uniqueness: true
  validates :name, presence: true

  scope :ordered, -> { order(Arel.sql("LOWER(name) ASC")) }

  def needs_refresh?
    synced_at.nil? || synced_at < REFRESH_INTERVAL.ago
  end
  def to_param
    country_code
  end
end

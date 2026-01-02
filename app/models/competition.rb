# frozen_string_literal: true

class Competition < ApplicationRecord
  REFRESH_INTERVAL = 60.seconds

  belongs_to :country, primary_key: :country_code, foreign_key: :country_code, optional: true
  has_many :events, primary_key: :betfair_id, foreign_key: :betfair_competition_id

  validates :betfair_id, presence: true, uniqueness: true
  validates :name, :country_code, presence: true
  validates :position, uniqueness: { scope: :country_code }, allow_nil: true

  scope :for_country, ->(country_code) { where(country_code: country_code) if country_code.present? }
  scope :ordered_by_name, -> { order(Arel.sql("LOWER(name) ASC")) }
  scope :ordered_by_position, lambda {
    reorder(
      Arel.sql("CASE WHEN position IS NULL THEN 1 ELSE 0 END"),
      :position,
      Arel.sql("LOWER(name) ASC")
    )
  }

  def self.ensure_synced_for_country!(country_code, max_age: REFRESH_INTERVAL)
    return none unless country_code.present?

    sync_for_country!(country_code) if needs_refresh_for_country?(country_code, max_age: max_age)

    for_country(country_code).ordered_by_name
  end

  def self.sync_for_country!(country_code, api: nil)
    return [] unless country_code.present?

    api ||= BetfairApi.new
    payloads = api.list_competitions([country_code])
    payloads.filter_map do |payload|
      betfair_competition = payload["competition"] || {} rescue binding.pry
      betfair_id = betfair_competition["id"]
      next unless betfair_id.present?

      record = find_or_initialize_by(betfair_id: betfair_id)
      record.assign_attributes(
        name: betfair_competition["name"],
        competition_region: payload["competitionRegion"],
        country_code: country_code,
        synced_at: Time.current
      )
      record.save!
      record
    end
  end

  def self.needs_refresh_for_country?(country_code, max_age: REFRESH_INTERVAL)
    relation = for_country(country_code)
    return true unless relation.exists?

    return false unless max_age

    relation.where("synced_at IS NULL OR synced_at < ?", max_age.ago).exists?
  end

  def to_param
    betfair_id
  end
end

# frozen_string_literal: true

class Country < ApplicationRecord
  REFRESH_INTERVAL = 60.minutes

  has_many :competitions, primary_key: :country_code, foreign_key: :country_code

  validates :country_code, presence: true, uniqueness: true
  validates :name, presence: true

  scope :ordered, -> { order(Arel.sql("LOWER(name) ASC")) }

  def self.ensure_synced!(max_age: REFRESH_INTERVAL)
    sync_all! if needs_refresh?(max_age: max_age)
    ordered
  end

  def self.sync_all!
    payloads = BetfairApi.new.list_countries
    payloads.each do |payload|
      code = payload["countryCode"].presence
      next unless code

      iso_country = ISO3166::Country[code]
      record = find_or_initialize_by(country_code: code)
      record.assign_attributes(
        betfair_name: payload["name"],
        market_count: payload["marketCount"].to_i,
        name: prettiest_country_name(iso_country, payload["name"], code),
        flag: iso_country&.respond_to?(:emoji_flag) ? iso_country.emoji_flag : nil,
        region: iso_country&.region,
        subregion: iso_country&.subregion,
        synced_at: Time.current
      )
      record.save!
    end
  end

  def self.needs_refresh?(max_age: REFRESH_INTERVAL)
    return true unless exists?
    return true unless max_age

    where("synced_at IS NULL OR synced_at < ?", max_age.ago).exists?
  end

  def self.prettiest_country_name(iso_country, fallback_name, country_code)
    return fallback_name.presence || country_code unless iso_country

    translations = iso_country.respond_to?(:translations) ? iso_country.translations : nil
    [
      iso_country.try(:common_name),
      iso_country.try(:iso_short_name),
      translations&.dig("en"),
      iso_country.try(:name),
      fallback_name,
      country_code
    ].find(&:present?)
  end

  def to_param
    country_code
  end
end

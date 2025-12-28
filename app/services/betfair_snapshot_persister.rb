# frozen_string_literal: true

require "time"
require "bigdecimal"

class BetfairSnapshotPersister
  def self.persist_for_competition!(competition_id)
    matches = BetfairApi.new.fetch_match_odds_by_competition(competition_id, persist: false)
    new(matches: matches).persist!
  end

  def initialize(matches:, captured_at: Time.current)
    @matches = Array(matches)
    @captured_at = captured_at
  end

  def persist!
    return if matches.blank?

    ActiveRecord::Base.transaction do
      matches.each { |match| persist_match(match) }
    end
  end

  private

  attr_reader :matches, :captured_at

  def persist_match(match)
    return if match[:betfair_event_id].blank?

    event = Event.find_or_initialize_by(betfair_event_id: match[:betfair_event_id])
    event.assign_attributes(
      name: match[:event_name],
      betfair_competition_id: match[:betfair_competition_id],
      kick_off: parse_time(match[:kick_off])
    )
    event.save!

    market = Market.find_or_initialize_by(betfair_market_id: match[:market_id])
    market.assign_attributes(
      event: event,
      name: match[:market_name],
      status: match[:status],
      inplay: !!match[:inplay],
      last_synced_at: captured_at
    )
    market.save!

    Array(match[:runners]).each do |runner|
      persist_competitor(market, runner)
    end
  end

  def persist_competitor(market, runner)
    selection_id = runner[:selection_id]
    return unless selection_id.present?

    competitor = market.competitors.find_or_initialize_by(selection_id: selection_id.to_s)
    competitor.name = runner[:name]
    competitor.save!

    percentage = normalize_percentage(runner[:percentage])
    return unless percentage

    existing_price = competitor.prices.find_by(captured_at: captured_at)
    if existing_price
      return if existing_price.percentage == percentage

      existing_price.update!(percentage: percentage)
      return
    end

    latest_price = competitor.prices.order(captured_at: :desc).first
    return if latest_price&.percentage == percentage

    competitor.prices.create!(captured_at: captured_at, percentage: percentage)
  end

  def normalize_percentage(value)
    return if value.nil?

    BigDecimal(value.to_s).round(2)
  end

  def parse_time(value)
    return value if value.is_a?(ActiveSupport::TimeWithZone)
    return value.to_time if value.respond_to?(:to_time)

    Time.zone ? Time.zone.parse(value.to_s) : Time.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end

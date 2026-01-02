# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  def home
    @hero_metrics = [
      { label: 'Average Edge', value: '+12.4%', caption: 'vs. closing line' },
      { label: 'Win Rate', value: '68%', caption: 'verified last 30 days' },
      { label: 'Sports Covered', value: '27', caption: 'updated hourly' }
    ]

    @feature_cards = [
      {
        title: 'Signal Engine',
        body: 'Ingests 15k+ markets nightly and ranks them by true price vs. sportsbook odds.',
        badge: 'AI Core'
      },
      {
        title: 'Market Radar',
        body: 'Tracks steam moves across major books to verify that every pick still has value.',
        badge: 'Realtime'
      },
      {
        title: 'Confidence Coach',
        body: 'Explains why a projection pops so you can bet with conviction.',
        badge: 'Insights'
      }
    ]

    @prediction_feed = build_prediction_feed(limit: 4)

    @value_spots = [
      { label: 'Sharp AI Plays', detail: 'Auto-filtered for 8%+ edge across 12 books.' },
      { label: 'Beat The Closing Line', detail: 'Average CLV swing of +18 cents per wager.' },
      { label: 'Personalized Cards', detail: 'Sync sportsbooks to tailor the slip to you.' }
    ]

    @next_up_event = load_next_up_event
  end

  def profile
    @profile_props = {
      component: 'profile-shell',
      profileEndpoint: api_v1_profile_path,
      copy: {
        heading: 'Your Stat Machine profile',
        subheading: 'Authenticate with Firebase to sync tickets and personalized insights.'
      }
    }
  end

  private

  def load_next_up_event
    Country
      .includes(competitions: { events: [:competition, { markets: { competitors: :prices } }] })
      .first&.competitions&.first&.events&.first
  end

  def build_prediction_feed(limit: 4)
    events = Event.includes({ competition: :country }, markets: { competitors: :prices })
                  .order(Arel.sql('RANDOM()'))
                  .limit(limit * 3)

    feed = events.filter_map { |event| serialize_prediction_feed_event(event) }.first(limit)
    feed.presence || default_prediction_feed
  end

  def serialize_prediction_feed_event(event)
    return unless event

    league = event.competition&.name.presence || event.competition&.country&.name || 'Featured league'
    match_label = prediction_match_label(event)
    kickoff = event.kick_off&.iso8601
    return if match_label.blank? || kickoff.blank?

    predicted_confidence = prediction_confidence_value(event)
    market_confidence = event.primary_market&.latest_probabilities&.map { |prob| prob[:percentage].to_f }.max
    confidence_value = predicted_confidence || market_confidence || default_confidence_value
    probability_value = (confidence_value / 100.0).round(2).clamp(0, 1)
    edge_value = compute_edge_value(predicted_confidence, market_confidence)

    {
      league: league,
      match: match_label,
      kickoff: kickoff,
      confidence: confidence_value.round,
      probability: probability_value,
      edge: format_edge_label(edge_value),
      trend: determine_trend_label(edge_value)
    }
  end

  def prediction_match_label(event)
    home_name = event.home_team_name.presence
    away_name = event.away_team_name.presence

    if home_name.blank? || away_name.blank?
      name_parts = split_event_name(event.name)
      home_name ||= name_parts.first
      away_name ||= name_parts[1]
    end

    if home_name.present? && away_name.present?
      "#{home_name} vs #{away_name}"
    else
      event.name
    end
  end

  def split_event_name(name)
    return [] if name.blank?

    separators = [/\s+vs\.?\s+/i, /\s+@\s+/, /\s+v\s+/i]
    separators.each do |separator|
      parts = name.split(separator).map { |part| part.to_s.strip }.reject(&:blank?)
      return parts if parts.size >= 2
    end

    name.split(/\s+vs\s+|\s+@\s+|\s+v\s+/i).map { |part| part.to_s.strip }.reject(&:blank?)
  end

  def prediction_confidence_value(event)
    percent_values = event.predictions&.dig('predictions', 'percent')
    return unless percent_values.is_a?(Hash)

    percent_values.values.map { |value| normalize_percentage_value(value) }.compact.max
  end

  def normalize_percentage_value(value)
    return if value.blank?

    cleaned = value.to_s.delete('%')
    return if cleaned.blank?

    cleaned.to_f
  end

  def compute_edge_value(predicted_confidence, market_confidence)
    if predicted_confidence && market_confidence
      predicted_confidence - market_confidence
    elsif predicted_confidence
      predicted_confidence - 50
    elsif market_confidence
      market_confidence - 50
    end
  end

  def format_edge_label(edge_value)
    return 'Edge syncing' unless edge_value

    formatted = format('%.1f', edge_value)
    prefix = edge_value.positive? ? '+' : ''
    "#{prefix}#{formatted}% value"
  end

  def determine_trend_label(edge_value)
    return 'Watch' unless edge_value

    return 'Rising' if edge_value >= 8
    return 'Stable' if edge_value >= 3
    return 'Cooling' if edge_value <= -2

    'Watch'
  end

  def default_confidence_value
    57
  end

  def default_prediction_feed
    now = (Time.zone || Time).now
    [
      {
        league: 'Premier League',
        match: 'Arsenal vs. Chelsea',
        kickoff: (now + 8.hours).iso8601,
        confidence: 93,
        probability: 0.67,
        edge: '+11.4% value',
        trend: 'Rising'
      },
      {
        league: 'NBA',
        match: 'Warriors @ Nuggets',
        kickoff: (now + 5.hours).iso8601,
        confidence: 88,
        probability: 0.61,
        edge: '+9.7% value',
        trend: 'Stable'
      },
      {
        league: 'Serie A',
        match: 'Inter vs. Juventus',
        kickoff: (now + 26.hours).iso8601,
        confidence: 84,
        probability: 0.58,
        edge: '+7.9% value',
        trend: 'Building'
      },
      {
        league: 'NFL Futures',
        match: 'Eagles season wins',
        kickoff: (now + 14.days).iso8601,
        confidence: 80,
        probability: 0.63,
        edge: '+6.3% value',
        trend: 'Watch'
      }
    ]
  end
end

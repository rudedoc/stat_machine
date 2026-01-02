module PagesHelper
  def next_up_card_state(event)
    return { present?: false } unless event

    primary_market = event.primary_market
    home_name, away_name = derive_matchup_names(event)
    kickoff_countdown = kickoff_countdown_label(event)
    edge_value = edge_confidence_value(event)

    {
      present?: true,
      status_badge_class: status_badge_class(primary_market),
      status_badge_label: status_badge_label(primary_market),
      matchup_label: matchup_label(event, home_name, away_name),
      context_line: context_line(event),
      competition_name: event.competition&.name || 'Featured matchup',
      home_name: home_name || 'Home',
      away_name: away_name || 'Away',
      home_logo: event.home_team_logo,
      away_logo: event.away_team_logo,
      kickoff_label: kickoff_label(event),
      kickoff_countdown_label: kickoff_countdown,
      edge_confidence_value: edge_value,
      edge_confidence_display: format_edge_confidence(edge_value),
      probability_chips: probability_chips(event, home_name, away_name, kickoff_countdown)
    }
  end

  private

  def status_badge_class(primary_market)
    if primary_market&.inplay?
      'bg-danger text-uppercase fw-semibold'
    elsif primary_market&.status.present?
      'bg-success text-uppercase fw-semibold'
    else
      'bg-secondary text-uppercase fw-semibold'
    end
  end

  def status_badge_label(primary_market)
    if primary_market&.inplay?
      'Live now'
    elsif primary_market&.status.present?
      primary_market.status.titleize
    else
      'Tracking'
    end
  end

  def derive_matchup_names(event)
    home_name = event.home_team_name.presence || event.predicted_home_team['name']
    away_name = event.away_team_name.presence || event.predicted_away_team['name']

    if home_name.blank? && event.name.present?
      name_parts = event.name.split(' vs ')
      name_parts = event.name.split(' @ ') if name_parts.size < 2
      home_name = name_parts.first&.strip
      away_name ||= name_parts.second&.strip
    end

    [home_name, away_name]
  end

  def matchup_label(event, home_name, away_name)
    if home_name.present? && away_name.present?
      "#{home_name} vs. #{away_name}"
    else
      event.name
    end
  end

  def context_line(event)
    competition_name = event.competition&.name
    country_name = event.competition&.country&.name
    [competition_name, country_name].compact.join(' · ').presence || 'Edge surfaced from the latest synced markets.'
  end

  def kickoff_label(event)
    kickoff_time = event.kick_off&.in_time_zone
    kickoff_time ? kickoff_time.strftime('%a %d %b · %H:%M %Z') : 'TBD'
  end

  def kickoff_countdown_label(event)
    kickoff_time = event.kick_off&.in_time_zone
    return nil unless kickoff_time

    countdown = distance_of_time_in_words(current_time_reference, kickoff_time)
    "in #{countdown}"
  end

  def current_time_reference
    Time.zone ? Time.zone.now : Time.current
  end

  def percentage_values(event)
    percentages = event.predictions&.dig('predictions', 'percent') || {}
    {
      home: percentages['home'],
      draw: percentages['draw'],
      away: percentages['away']
    }
  end

  def parse_percentage_value(value)
    return nil if value.blank?

    value.to_s.delete('%').to_f
  end

  def format_percentage_display(value)
    return '--' if value.blank?

    value_str = value.to_s
    value_str.include?('%') ? value_str : number_to_percentage(value_str.to_f, precision: 1)
  end

  def edge_confidence_value(event)
    values = percentage_values(event).values.map { |value| parse_percentage_value(value) }.compact
    values.max
  end

  def format_edge_confidence(value)
    value ? number_to_percentage(value, precision: 1) : 'Syncing'
  end

  def probability_chips(event, home_name, away_name, kickoff_chip_value)
    values = percentage_values(event)
    chips = [
      { value: format_percentage_display(values[:home]), label: "#{home_name.presence || 'Home'} win".strip },
      { value: format_percentage_display(values[:draw]), label: 'Draw probability' },
      { value: format_percentage_display(values[:away]), label: "#{away_name.presence || 'Away'} win".strip }
    ]

    chips << { value: kickoff_chip_value, label: 'Until kickoff' } if kickoff_chip_value.present?
    chips
  end
end

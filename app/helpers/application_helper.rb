module ApplicationHelper
  TAG_CATEGORY_BADGE_CLASSES = {
    'team' => 'bg-primary bg-opacity-10 text-primary border border-primary border-opacity-25',
    'person' => 'bg-warning bg-opacity-10 text-warning border border-warning border-opacity-25',
    'competition' => 'bg-info bg-opacity-10 text-info border border-info border-opacity-25',
    'status' => 'bg-success bg-opacity-10 text-success border border-success border-opacity-25'
  }.freeze

  SENTIMENT_BADGE_CLASSES = {
    'positive' => 'bg-success bg-opacity-10 text-success border border-success border-opacity-25',
    'neutral' => 'bg-secondary bg-opacity-10 text-secondary border border-secondary border-opacity-25',
    'negative' => 'bg-danger bg-opacity-10 text-danger border border-danger border-opacity-25'
  }.freeze

  SENTIMENT_BAR_CLASSES = {
    'positive' => 'bg-success',
    'neutral' => 'bg-secondary',
    'negative' => 'bg-danger'
  }.freeze

  def tag_badge_class(tag)
    category_key = tag&.category.to_s.downcase
    TAG_CATEGORY_BADGE_CLASSES.fetch(category_key, 'bg-secondary bg-opacity-10 text-secondary border border-secondary border-opacity-25')
  end

  def tag_category_label(tag)
    label = tag&.category.to_s
    label.present? ? label.titleize : 'Tag'
  end

  def sentiment_indicator_badge_class(sentiment)
    SENTIMENT_BADGE_CLASSES.fetch(sentiment.to_s, SENTIMENT_BADGE_CLASSES['neutral'])
  end

  def sentiment_indicator_bar_class(sentiment)
    SENTIMENT_BAR_CLASSES.fetch(sentiment.to_s, SENTIMENT_BAR_CLASSES['neutral'])
  end

  def sentiment_score_percent(score)
    (((score.to_f + 1.0) / 2.0) * 100).clamp(0, 100)
  end

  def sentiment_score_display(score)
    return '--' if score.nil?

    formatted = number_with_precision(score, precision: 2)
    score.positive? ? "+#{formatted}" : formatted
  end

  def sentiment_breakdown_label(snapshot)
    return 'No coverage yet' if snapshot.blank?

    breakdown = {
      positive: snapshot[:positive_count],
      neutral: snapshot[:neutral_count],
      negative: snapshot[:negative_count]
    }.map do |sentiment, count|
      next if count.to_i.zero?

      label = sentiment.to_s.titleize
      "#{count} #{label}"
    end.compact.join(' · ')

    breakdown.presence || 'No coverage yet'
  end
end

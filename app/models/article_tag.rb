class ArticleTag < ApplicationRecord
  SENTIMENT_VALUES = %w[positive neutral negative].freeze

  belongs_to :article
  belongs_to :tag

  validates :sentiment, inclusion: { in: SENTIMENT_VALUES }
  validates :sentiment_score,
            numericality: { greater_than_or_equal_to: -1.0, less_than_or_equal_to: 1.0 }

  class << self
    def sentiment_summary_for(tag_ids)
      tag_ids = Array(tag_ids).compact
      return {} if tag_ids.empty?

      select_clause = <<~SQL.squish
        tag_id,
        AVG(sentiment_score) AS avg_score,
        COUNT(*) AS total_mentions,
        SUM(CASE WHEN sentiment = 'positive' THEN 1 ELSE 0 END) AS positive_count,
        SUM(CASE WHEN sentiment = 'neutral' THEN 1 ELSE 0 END) AS neutral_count,
        SUM(CASE WHEN sentiment = 'negative' THEN 1 ELSE 0 END) AS negative_count
      SQL

      where(tag_id: tag_ids)
        .group(:tag_id)
        .select(select_clause)
        .each_with_object({}) do |record, memo|
          avg_score = record.avg_score.to_f
          memo[record.tag_id] = {
            avg_score: avg_score,
            total_mentions: record.total_mentions.to_i,
            positive_count: record.positive_count.to_i,
            neutral_count: record.neutral_count.to_i,
            negative_count: record.negative_count.to_i,
            sentiment: sentiment_label_for_score(avg_score)
          }
        end
    end

    def sentiment_label_for_score(score)
      return "neutral" if score.nil?
      return "positive" if score > 0.1
      return "negative" if score < -0.1

      "neutral"
    end
  end
end

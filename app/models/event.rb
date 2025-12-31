# frozen_string_literal: true

class Event < ApplicationRecord
  belongs_to :competition, primary_key: :betfair_id, foreign_key: :betfair_competition_id, optional: true
  has_many :markets, dependent: :destroy
  has_many :competitors, through: :markets
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings

  validates :betfair_event_id, presence: true, uniqueness: true
  validates :betfair_competition_id, :name, :kick_off, presence: true

  scope :upcoming, -> { where('kick_off >= ?', Time.current) }
  default_scope -> { upcoming }

  def primary_market
    markets.max_by { |market| market.last_synced_at || market.updated_at }
  end

  def predicted_home_team
    predicted_team_for('home')
  end

  def predicted_away_team
    predicted_team_for('away')
  end

  def home_team_logo
    predicted_home_team['logo']
  end

  def away_team_logo
    predicted_away_team['logo']
  end

  def home_team_name
    predicted_home_team['name']
  end

  def away_team_name
    predicted_away_team['name']
  end

  def to_param
    betfair_event_id
  end

  def sync_stats_for_event(event)
    return unless event.sportmonks_fixture_id

    data = SportmonksClient.new.fixture_stats(event.sportmonks_fixture_id)
    stats = data.dig('data', 'statistics')

    # Logic to save stats (e.g., event.update(external_stats: stats))
  end

  def related_articles(limit: 6)
    tag_ids = related_tag_ids
    return [] if tag_ids.empty?

    Article
      .includes(:feed_source)
      .where(id: ArticleTag.select(:article_id).where(tag_id: tag_ids))
      .order(Arel.sql('COALESCE(articles.published_at, articles.created_at) DESC'))
      .limit(limit)
      .to_a
  end

  private

  def predicted_team_for(side)
    return {} unless predictions.respond_to?(:dig)

    predictions.dig('teams', side.to_s) || {}
  end

  def related_tag_ids
    event_tags = tags.loaded? ? tags : tags.to_a
    competitor_tags = if markets.loaded?
                        markets.flat_map do |market|
                          market.competitors.flat_map { |competitor| competitor.tags.loaded? ? competitor.tags : competitor.tags.to_a }
                        end
                      else
                        []
                      end

    (event_tags + competitor_tags).map(&:id).compact.uniq
  end
end

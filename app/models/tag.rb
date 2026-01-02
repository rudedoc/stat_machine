class Tag < ApplicationRecord
  has_many :article_tags, dependent: :destroy
  has_many :articles, through: :article_tags
  has_many :taggings, dependent: :destroy
  has_many :events, -> { where(taggings: { taggable_type: 'Event' }) }, through: :taggings, source: :taggable, source_type: 'Event'
  has_many :competitors, -> { where(taggings: { taggable_type: 'Competitor' }) }, through: :taggings, source: :taggable, source_type: 'Competitor'

  after_commit :link_related_entities, on: %i[create update], if: :linkable_change?
  before_save :normalize_aliases

  # Validations ensure we don't have "Arsenal" and "arsenal"
  validates :name, presence: true, uniqueness: { scope: :category, case_sensitive: false }

  # Scopes for easy access
  scope :teams, -> { where(category: 'team') }
  scope :players, -> { where(category: 'person') }

  def self.identify(raw_text, category: nil)
    clean_text = raw_text.to_s.downcase.strip
    return nil if clean_text.blank?

    relation = category.present? ? where(category: category) : all

    # 1. Check the standard columns (Exact match)
    match = relation.where("lower(name) = ?", clean_text).first
    return match if match

    alias_match_sql = <<~SQL.squish
      EXISTS (
        SELECT 1
        FROM unnest(COALESCE(tags.aliases, ARRAY[]::varchar[])) AS alias_name
        WHERE lower(alias_name) = ?
      )
    SQL

    relation.where(alias_match_sql, clean_text).first
  end

  def self.find_or_create_by_name_or_alias!(raw_text, category:)
    clean_text = raw_text.to_s.strip
    return nil if clean_text.blank?

    identify(clean_text, category: category) || create!(name: clean_text, category: category)
  end

  def matches?(text)
    downcased = text.to_s.downcase
    name.to_s.downcase == downcased || Array(aliases).any? { |alias_name| alias_name.to_s.downcase == downcased }
  end

  # Reassigns taggings and article tags from alias records back to the canonical tag
  def merge_duplicate_alias_records!(candidate_names = aliases)
    normalized_names = Array(candidate_names).map { |value| value.to_s.downcase.strip }
                                         .reject(&:blank?).uniq
    return 0 if normalized_names.empty?

    duplicates = Tag.where(category: category)
                    .where("LOWER(name) IN (?)", normalized_names)
                    .where.not(id: id)

    merged = 0

    transaction do
      duplicates.find_each do |duplicate|
        merged += 1
        reassign_alias_records!(duplicate)
        duplicate.destroy!
      end
    end

    merged
  end

  private

  def normalize_aliases
    self.aliases = Array(aliases).map { |alias_name| alias_name.to_s.strip.downcase }
                               .reject(&:blank?).uniq
  end

  def linkable_change?
    saved_change_to_name? || saved_change_to_aliases?
  end

  def link_related_entities
    TagLinker.link_tag!(self)
  end

  def reassign_alias_records!(duplicate)
    duplicate.taggings.find_each do |tagging|
      existing = Tagging.find_by(tag_id: id,
                                 taggable_type: tagging.taggable_type,
                                 taggable_id: tagging.taggable_id)

      if existing
        tagging.destroy!
      else
        tagging.update!(tag: self)
      end
    end

    duplicate.article_tags.find_each do |article_tag|
      existing = ArticleTag.find_by(article_id: article_tag.article_id, tag_id: id)

      if existing
        if prefer_article_tag_update?(existing, article_tag)
          existing.update!(sentiment: article_tag.sentiment,
                           sentiment_score: article_tag.sentiment_score)
        end

        article_tag.destroy!
      else
        article_tag.update!(tag: self)
      end
    end
  end

  def prefer_article_tag_update?(current, incoming)
    return false if incoming.sentiment.blank?

    current.sentiment == 'neutral' && incoming.sentiment != 'neutral' ||
      incoming.sentiment_score.to_f.abs > current.sentiment_score.to_f.abs
  end
end

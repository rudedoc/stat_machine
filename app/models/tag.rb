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

  def self.identify(raw_text)
    clean_text = raw_text.to_s.downcase.strip
    return nil if clean_text.blank?

    # 1. Check the standard columns (Exact match)
    match = where("lower(name) = ?", clean_text).first
    return match if match

    alias_match_sql = <<~SQL.squish
      EXISTS (
        SELECT 1
        FROM unnest(COALESCE(tags.aliases, ARRAY[]::varchar[])) AS alias_name
        WHERE lower(alias_name) = ?
      )
    SQL

    where(alias_match_sql, clean_text).first
  end

  def matches?(text)
    downcased = text.to_s.downcase
    name.to_s.downcase == downcased || Array(aliases).any? { |alias_name| alias_name.to_s.downcase == downcased }
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
end

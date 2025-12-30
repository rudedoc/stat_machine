class Tag < ApplicationRecord
  has_many :article_tags, dependent: :destroy
  has_many :articles, through: :article_tags

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

    where("? = ANY(aliases)", clean_text).first
  end

  def matches?(text)
    downcased = text.downcase
    name.downcase == downcased || aliases.include?(downcased)
  end
end

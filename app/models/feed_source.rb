# frozen_string_literal: true

class FeedSource < ApplicationRecord
  has_many :articles, dependent: :destroy
  has_many :article_tags, through: :articles
  has_many :tags, through: :article_tags

  validates :name, presence: true
  validates :feed_url, presence: true, uniqueness: true

  def articles_count
    return self[:articles_count].to_i if has_attribute?(:articles_count)

    articles.count
  end

  def last_activity_at
    last_imported_at || last_checked_at || updated_at || created_at
  end

  def recently_synced?(window: 12.hours)
    return false unless last_activity_at

    last_activity_at >= window.ago
  end
end

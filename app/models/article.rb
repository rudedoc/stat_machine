class Article < ApplicationRecord
  belongs_to :feed_source

  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags

  validates :url, presence: true, uniqueness: true
end

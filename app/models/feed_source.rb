# frozen_string_literal: true

class FeedSource < ApplicationRecord
  has_many :articles, dependent: :destroy

  validates :name, presence: true
  validates :feed_url, presence: true, uniqueness: true
end

# frozen_string_literal: true

class FeedSource < ApplicationRecord
  validates :name, presence: true
  validates :feed_url, presence: true, uniqueness: true
end

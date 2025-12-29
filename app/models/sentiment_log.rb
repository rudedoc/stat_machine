class SentimentLog < ApplicationRecord
  belongs_to :team
  
  validates :source, presence: true
  validates :score, presence: true
end
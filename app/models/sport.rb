# app/models/sport.rb
class Sport < ApplicationRecord
  validates :external_id, presence: true, uniqueness: true
  validates :name, presence: true

  has_many :leagues, dependent: :destroy
end

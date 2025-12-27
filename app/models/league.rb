# app/models/league.rb
class League < ApplicationRecord
  self.inheritance_column = :_type_disabled

  belongs_to :sport
  belongs_to :country

  has_many :seasons, dependent: :destroy
  has_many :fixtures, dependent: :destroy

  validates :external_id, presence: true, uniqueness: true
end

# app/models/participant.rb
class Participant < ApplicationRecord
  self.inheritance_column = :_type_disabled

  belongs_to :sport
  belongs_to :country, optional: true # Some participants might not have a country assigned

  has_many :fixture_participants
  has_many :fixtures, through: :fixture_participants

  validates :external_id, presence: true, uniqueness: true
end

# app/models/fixture.rb
class Fixture < ApplicationRecord
  belongs_to :league
  belongs_to :season

  # Links to the join table we will create next
  has_many :predictions, dependent: :destroy
  has_many :fixture_participants, dependent: :destroy
  has_many :participants, through: :fixture_participants
  has_one :home_fixture_participant, -> { home }, class_name: 'FixtureParticipant'
  has_one :home_team, through: :home_fixture_participant, source: :participant

  validates :external_id, presence: true, uniqueness: true

  # Useful for your reporting app:
  scope :upcoming, -> { where('starting_at > ?', Time.current).order(starting_at: :asc) }
  scope :live, -> { where(state_id: 2) }
end

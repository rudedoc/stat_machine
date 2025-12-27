# app/models/fixture_participant.rb
class FixtureParticipant < ApplicationRecord
  belongs_to :fixture
  belongs_to :participant

  # Handy scopes for your views
  scope :home, -> { where(location: 'home') }
  scope :away, -> { where(location: 'away') }
  scope :winner, -> { where(winner: true) }
end

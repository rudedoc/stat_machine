# frozen_string_literal: true

class AddSportmonksIds < ActiveRecord::Migration[8.1]
  def change
    add_column :countries, :sportmonks_id, :integer
    add_column :competitions, :sportmonks_league_id, :integer
    add_column :events, :sportmonks_fixture_id, :integer
    add_column :competitors, :sportmonks_team_id, :integer
  end
end

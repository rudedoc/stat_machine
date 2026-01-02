class AddFootballApiLeagueIdToCompetitions < ActiveRecord::Migration[8.1]
  def change
    add_column :competitions, :football_api_league_id, :integer
    add_index :competitions, :football_api_league_id, unique: true
  end
end

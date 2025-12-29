class CreateTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :teams do |t|
      t.string :name
      t.string :short_name
      t.string :betfair_name
      t.integer :football_api_id
      t.string :aliases, array: true, default: []
      t.timestamps
    end

    add_index :teams, :aliases, using: :gin
  end
end

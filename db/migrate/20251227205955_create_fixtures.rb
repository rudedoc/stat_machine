class CreateFixtures < ActiveRecord::Migration[8.1]
  def change
    create_table :fixtures do |t|
      t.references :league, null: false, foreign_key: true
      t.references :season, null: false, foreign_key: true
      t.integer :external_id
      t.string :name
      t.datetime :starting_at
      t.integer :state_id
      t.integer :external_venue_id
      t.integer :round_id
      t.integer :stage_id
      t.string :leg
      t.string :result_info

      t.timestamps
    end
    add_index :fixtures, :external_id
  end
end

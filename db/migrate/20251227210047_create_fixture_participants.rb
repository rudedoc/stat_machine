class CreateFixtureParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :fixture_participants do |t|
      t.references :fixture, null: false, foreign_key: true
      t.references :participant, null: false, foreign_key: true
      t.string :location
      t.boolean :winner
      t.integer :position

      t.timestamps
    end
  end
end

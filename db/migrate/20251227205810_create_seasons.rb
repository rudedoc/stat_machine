class CreateSeasons < ActiveRecord::Migration[8.1]
  def change
    create_table :seasons do |t|
      t.references :league, null: false, foreign_key: true
      t.integer :external_id
      t.string :name
      t.boolean :is_current
      t.datetime :starting_at
      t.datetime :ending_at

      t.timestamps
    end
    add_index :seasons, :external_id
  end
end

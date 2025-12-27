class CreatePredictions < ActiveRecord::Migration[8.1]
  def change
    create_table :predictions do |t|
      t.references :fixture, null: false, foreign_key: true
      t.integer :external_id
      t.integer :type_id
      t.jsonb :predictions

      t.timestamps
    end
    add_index :predictions, :external_id
    add_index :predictions, :type_id
  end
end

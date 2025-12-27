class CreateParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :participants do |t|
      t.references :sport, null: false, foreign_key: true
      t.references :country, null: false, foreign_key: true
      t.integer :external_id
      t.string :name
      t.string :short_code
      t.string :image_path
      t.string :gender
      t.integer :founded
      t.string :type
      t.boolean :placeholder

      t.timestamps
    end
    add_index :participants, :external_id
  end
end

class CreateLeagues < ActiveRecord::Migration[8.1]
  def change
    create_table :leagues do |t|
      t.references :sport, null: false, foreign_key: true
      t.references :country, null: false, foreign_key: true
      t.integer :external_id
      t.string :name
      t.boolean :active
      t.string :short_code
      t.string :image_path
      t.string :type
      t.string :sub_type

      t.timestamps
    end
    add_index :leagues, :external_id
  end
end

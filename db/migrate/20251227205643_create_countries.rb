class CreateCountries < ActiveRecord::Migration[8.1]
  def change
    create_table :countries do |t|
      t.integer :external_id
      t.string :name
      t.string :image_path
      t.jsonb :extra_data

      t.timestamps
    end
    add_index :countries, :external_id
  end
end

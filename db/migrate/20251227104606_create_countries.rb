class CreateCountries < ActiveRecord::Migration[8.1]
  def change
    create_table :countries do |t|
      t.string :country_code, null: false
      t.string :betfair_name
      t.string :name, null: false
      t.integer :market_count, null: false, default: 0
      t.string :flag
      t.string :region
      t.string :subregion
      t.datetime :synced_at

      t.timestamps
    end

    add_index :countries, :country_code, unique: true
  end
end

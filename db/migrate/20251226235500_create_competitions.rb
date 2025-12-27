# frozen_string_literal: true

class CreateCompetitions < ActiveRecord::Migration[8.1]
  def change
    create_table :competitions do |t|
      t.string :betfair_id, null: false
      t.string :name, null: false
      t.string :country_code, null: false
      t.string :competition_region
      t.integer :market_count, null: false, default: 0
      t.datetime :synced_at

      t.timestamps
    end

    add_index :competitions, :betfair_id, unique: true
    add_index :competitions, :country_code
  end
end

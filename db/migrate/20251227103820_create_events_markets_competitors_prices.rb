class CreateEventsMarketsCompetitorsPrices < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :betfair_event_id, null: false
      t.string :betfair_competition_id, null: false
      t.string :name, null: false
      t.datetime :kick_off, null: false

      t.timestamps
    end
    add_index :events, :betfair_event_id, unique: true
    add_index :events, :betfair_competition_id

    create_table :markets do |t|
      t.references :event, null: false, foreign_key: true
      t.string :betfair_market_id, null: false
      t.string :name, null: false
      t.string :status
      t.boolean :inplay, null: false, default: false
      t.datetime :last_synced_at

      t.timestamps
    end
    add_index :markets, :betfair_market_id, unique: true

    create_table :competitors do |t|
      t.references :market, null: false, foreign_key: true
      t.string :selection_id, null: false
      t.string :name, null: false

      t.timestamps
    end
    add_index :competitors, [:market_id, :selection_id], unique: true

    create_table :prices do |t|
      t.references :competitor, null: false, foreign_key: true
      t.decimal :percentage, precision: 5, scale: 2, null: false
      t.datetime :captured_at, null: false

      t.timestamps
    end
    add_index :prices, [:competitor_id, :captured_at]
  end
end

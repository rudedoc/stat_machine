class CreatePrices < ActiveRecord::Migration[8.1]
  def change
    create_table :prices do |t|
      t.references :fixture, null: false, foreign_key: true
      t.references :market, null: false, foreign_key: true
      t.references :bookmaker, null: false, foreign_key: true
      t.bigint :external_id
      t.string :label
      t.string :value
      t.string :probability
      t.boolean :winning
      t.boolean :stopped
      t.string :handicap
      t.string :total

      t.timestamps
    end
    add_index :prices, :external_id
  end
end

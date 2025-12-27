class CreateMarkets < ActiveRecord::Migration[8.1]
  def change
    create_table :markets do |t|
      t.integer :external_id
      t.string :name
      t.string :developer_name
      t.boolean :has_winning_calculations

      t.timestamps
    end
    add_index :markets, :external_id
  end
end

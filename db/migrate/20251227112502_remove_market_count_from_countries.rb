class RemoveMarketCountFromCountries < ActiveRecord::Migration[8.1]
  def change
    remove_column :countries, :market_count, :integer, default: 0, null: false
  end
end

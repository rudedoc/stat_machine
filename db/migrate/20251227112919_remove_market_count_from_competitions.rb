class RemoveMarketCountFromCompetitions < ActiveRecord::Migration[8.1]
  def change
    remove_column :competitions, :market_count, :integer, default: 0, null: false
  end
end

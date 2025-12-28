class AddExchangeDataToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :exchange_data, :jsonb
  end
end

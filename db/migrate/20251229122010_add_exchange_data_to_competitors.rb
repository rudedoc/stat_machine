class AddExchangeDataToCompetitors < ActiveRecord::Migration[8.1]
  def change
    add_column :competitors, :exchange_data, :jsonb, default: {}, null: false
    
    # GIN index allows high-performance querying inside the JSON structure
    add_index :competitors, :exchange_data, using: :gin
  end
end

class AddFootballApiIdToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :football_api_id, :integer
    add_index :events, :football_api_id
  end
end

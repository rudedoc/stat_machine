class AddPredictionsToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :predictions, :jsonb
  end
end

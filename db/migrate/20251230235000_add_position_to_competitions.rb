# frozen_string_literal: true

class AddPositionToCompetitions < ActiveRecord::Migration[8.1]
  def change
    add_column :competitions, :position, :integer
    add_index :competitions, [:country_code, :position], unique: true
  end
end

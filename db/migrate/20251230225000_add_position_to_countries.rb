class AddPositionToCountries < ActiveRecord::Migration[8.1]
  def change
    add_column :countries, :position, :integer
  end
end

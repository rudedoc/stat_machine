class AddDetailsToTags < ActiveRecord::Migration[8.1]
  def change
    add_column :tags, :aliases, :string, array: true, default: []
    add_index :tags, :aliases, using: :gin
  end
end

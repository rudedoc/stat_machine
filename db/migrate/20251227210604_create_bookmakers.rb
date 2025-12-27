class CreateBookmakers < ActiveRecord::Migration[8.1]
  def change
    create_table :bookmakers do |t|
      t.integer :external_id
      t.string :name

      t.timestamps
    end
    add_index :bookmakers, :external_id
  end
end

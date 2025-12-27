class CreateSports < ActiveRecord::Migration[8.1]
  def change
    create_table :sports do |t|
      t.integer :external_id
      t.string :name

      t.timestamps
    end
    add_index :sports, :external_id
  end
end

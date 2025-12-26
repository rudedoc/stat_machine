class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :firebase_uid, null: false
      t.string :email
      t.string :display_name
      t.string :photo_url
      t.datetime :last_authenticated_at

      t.timestamps
    end

    add_index :users, :firebase_uid, unique: true
    add_index :users, :email
  end
end

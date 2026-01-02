# frozen_string_literal: true

class CreateFeedSources < ActiveRecord::Migration[8.1]
  def change
    create_table :feed_sources do |t|
      t.string :name, null: false
      t.string :feed_url, null: false
      t.datetime :last_checked_at
      t.datetime :last_imported_at

      t.timestamps
    end

    add_index :feed_sources, :feed_url, unique: true
    add_index :feed_sources, :last_checked_at
  end
end

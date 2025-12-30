class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.references :feed_source, null: false, foreign_key: true
      t.string :title
      t.string :url
      t.datetime :published_at
      t.text :content

      t.timestamps
    end
  end
end

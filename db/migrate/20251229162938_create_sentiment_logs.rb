class CreateSentimentLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :sentiment_logs do |t|
      t.references :team, null: false, foreign_key: true
      t.string :source
      t.string :author
      t.text :raw_text
      t.float :score
      t.datetime :captured_at

      t.timestamps
    end
  end
end

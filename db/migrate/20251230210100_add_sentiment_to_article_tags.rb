class AddSentimentToArticleTags < ActiveRecord::Migration[8.1]
  def change
    add_column :article_tags, :sentiment, :string, null: false, default: 'neutral'
    add_column :article_tags, :sentiment_score, :float, null: false, default: 0.0

    add_index :article_tags, :sentiment
  end
end

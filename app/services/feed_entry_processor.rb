# app/services/feed_entry_processor.rb
class FeedEntryProcessor
  def initialize(entry, feed_source)
    @entry = entry
    @feed_source = feed_source
  end

  def call
    # 1. Save the raw article first (Idempotency)
    article = Article.find_or_initialize_by(url: @entry.url)
    article.update!(
      title: @entry.title,
      content: @entry.text,
      published_at: @entry.published_at,
      feed_source: @feed_source
    )

    # 2. Perform NER (Ideally push this to a background job, e.g., EntityExtractionJob)
    entities = EntityExtractor.new(@entry.text).call

    # 3. Tag the article
    tag_entities(article, entities)
  end

  private

  def tag_entities(article, entities)
    # Assuming you have Tag and ArticleTag models
    entities["teams"]&.each do |team_name|
      # specific logic to find/create teams
      tag = Tag.find_or_create_by(name: team_name, category: 'team')
      article.tags << tag unless article.tags.include?(tag)
    end

    entities["persons"]&.each do |person_name|
      tag = Tag.find_or_create_by(name: person_name, category: 'person')
      article.tags << tag unless article.tags.include?(tag)
    end
  end
end

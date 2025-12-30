# app/services/feed_importer.rb
class FeedImporter
  def initialize(feed_source)
    @feed_source = feed_source
  end

  def call
    Rails.logger.info("Starting import for #{@feed_source.name}...")

    # 1. Fetch raw entries using your existing Fetcher
    entries = FeedSourceEntryFetcher.new(@feed_source).call

    new_count = 0

    entries.each do |entry|
      # 2. Idempotency check: Skip if we already have this URL
      next if Article.exists?(url: entry.url)

      # 3. Create the Article
      article = create_article(entry)

      # 4. Perform NER (Entity Extraction)
      # specific logic to handle the API call safely
      extract_and_tag(article) if article.persisted?

      new_count += 1
    end

    Rails.logger.info("Finished #{@feed_source.name}: Imported #{new_count} new articles.")
  end

  private

  def create_article(entry)
    Article.create(
      feed_source: @feed_source,
      title: entry.title,
      url: entry.url,
      published_at: entry.published_at || Time.current,
      content: entry.text
    )
  rescue ActiveRecord::RecordNotUnique
    # Handle race conditions where two processes insert the same URL simultaneously
    nil
  end

  def extract_and_tag(article)
    # 1. Call the AI service
    result = EntityExtractor.new(article.content).call

    # 2. Save Tags in a Transaction
    Article.transaction do
      # Tag Teams
      Array(result["teams"]).each do |team_name|
        # Normalize name (optional): team_name.strip.titleize
        tag = Tag.find_or_create_by(name: team_name, category: 'team')
        ArticleTag.find_or_create_by(article: article, tag: tag)
      end

      # Tag Persons
      Array(result["persons"]).each do |person_name|
        tag = Tag.find_or_create_by(name: person_name, category: 'person')
        ArticleTag.find_or_create_by(article: article, tag: tag)
      end
    end
  end
end

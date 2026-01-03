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
      # 2-3. Create or find the Article idempotently
      article, created = find_or_create_article(entry)

      # 4. Perform NER (Entity Extraction) ONLY for newly imported articles
      next unless created && article&.persisted?

      extract_and_tag(article)
      new_count += 1
    end

    Rails.logger.info("Finished #{@feed_source.name}: Imported #{new_count} new articles.")
  end

  private

  def find_or_create_article(entry)
    sanitized_title = sanitize_title(entry.title)

    article = Article.find_or_create_by(url: entry.url) do |a|
      a.feed_source   = @feed_source
      a.title         = sanitized_title
      a.published_at  = entry.published_at || Time.current
      a.content       = entry.text
    end

    # If the record was created in this call, Rails will have an id change
    created = article.previous_changes.key?("id")
    ensure_plain_text_title(article, sanitized_title) unless created
    [ article, created ]
  rescue ActiveRecord::RecordNotUnique
    # If a race condition occurred, fetch the existing record and mark as not created
    existing = Article.find_by(url: entry.url)
    [ existing, false ]
  end

  def sanitize_title(title)
    PlainTextSanitizer.call(title)
  end

  def ensure_plain_text_title(article, sanitized_title)
    return if sanitized_title.blank?
    return if article.title == sanitized_title

    article.update!(title: sanitized_title)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn("FeedImporter: unable to sanitize title for article #{article.id} - #{e.message}")
  end

  def extract_and_tag(article)
    # 1. Call the AI service
    result = EntityExtractor.new(article.content).call

    team_sentiments = sentiment_lookup(result["team_sentiments"])
    person_sentiments = sentiment_lookup(result["person_sentiments"])

    # 2. Save Tags in a Transaction
    Article.transaction do
      # Tag Teams
      Array(result["teams"]).each do |team_name|
        cleaned_name = clean_entity_name(team_name)
        next if cleaned_name.blank?

        tag = Tag.find_or_create_by_name_or_alias!(cleaned_name, category: "team")
        next unless tag
        upsert_article_tag(
          article,
          tag,
          team_sentiments[normalize_entity_name(cleaned_name)]
        )
      end

      # Tag Persons
      Array(result["persons"]).each do |person_name|
        cleaned_name = clean_entity_name(person_name)
        next if cleaned_name.blank?

        tag = Tag.find_or_create_by_name_or_alias!(cleaned_name, category: "person")
        next unless tag
        upsert_article_tag(
          article,
          tag,
          person_sentiments[normalize_entity_name(cleaned_name)]
        )
      end
    end
  end

  def sentiment_lookup(entries)
    Array(entries).each_with_object({}) do |entry, memo|
      normalized_name = normalize_entity_name(entry["name"])
      next if normalized_name.blank?

      memo[normalized_name] = {
        sentiment: sanitize_sentiment(entry["sentiment"]),
        sentiment_score: sanitize_score(entry["score"])
      }
    end
  end

  def upsert_article_tag(article, tag, sentiment_attributes)
    attributes = sentiment_attributes || default_sentiment_attributes
    article_tag = ArticleTag.find_or_initialize_by(article: article, tag: tag)
    article_tag.assign_attributes(attributes)
    article_tag.save! if article_tag.changed?
  end

  def clean_entity_name(name)
    name.to_s.strip
  end

  def normalize_entity_name(name)
    clean_entity_name(name).downcase
  end

  def sanitize_sentiment(value)
    sentiment = value.to_s.downcase
    return sentiment if ArticleTag::SENTIMENT_VALUES.include?(sentiment)

    "neutral"
  end

  def sanitize_score(value)
    value.to_f.clamp(-1.0, 1.0)
  rescue NoMethodError
    0.0
  end

  def default_sentiment_attributes
    { sentiment: "neutral", sentiment_score: 0.0 }
  end
end

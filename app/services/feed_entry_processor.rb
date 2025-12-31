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
    team_sentiments = sentiment_lookup(entities["team_sentiments"])
    person_sentiments = sentiment_lookup(entities["person_sentiments"])

    Array(entities["teams"]).each do |team_name|
      cleaned_name = clean_entity_name(team_name)
      next if cleaned_name.blank?

      tag = Tag.find_or_create_by(name: cleaned_name, category: 'team')
      upsert_article_tag(
        article,
        tag,
        team_sentiments[normalize_entity_name(cleaned_name)]
      )
    end

    Array(entities["persons"]).each do |person_name|
      cleaned_name = clean_entity_name(person_name)
      next if cleaned_name.blank?

      tag = Tag.find_or_create_by(name: cleaned_name, category: 'person')
      upsert_article_tag(
        article,
        tag,
        person_sentiments[normalize_entity_name(cleaned_name)]
      )
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

    'neutral'
  end

  def sanitize_score(value)
    value.to_f.clamp(-1.0, 1.0)
  rescue NoMethodError
    0.0
  end

  def default_sentiment_attributes
    { sentiment: 'neutral', sentiment_score: 0.0 }
  end
end

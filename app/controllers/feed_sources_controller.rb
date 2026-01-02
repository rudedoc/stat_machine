# app/controllers/feed_sources_controller.rb
class FeedSourcesController < ApplicationController
  def index
    @feed_sources = FeedSource
                      .left_outer_joins(:articles)
                      .select('feed_sources.*, COUNT(articles.id) AS articles_count')
                      .group('feed_sources.id')
                      .order(Arel.sql('COALESCE(feed_sources.last_imported_at, feed_sources.last_checked_at, feed_sources.created_at) DESC'))
                      .load
    @total_feeds = @feed_sources.length
    @total_articles = Article.count
    @recently_synced_count = FeedSource.where('last_imported_at >= :window OR last_checked_at >= :window', window: 24.hours.ago).distinct.count
    @stale_feed_count = [@total_feeds - @recently_synced_count, 0].max
  end

  def show
    @feed_source = FeedSource.find(params[:id])
    @recent_articles = @feed_source.articles
                                   .includes(article_tags: :tag)
                                   .order(Arel.sql('COALESCE(articles.published_at, articles.created_at) DESC'))
                                   .limit(25)
    @articles_count = @feed_source.articles.count

    tag_ids = @recent_articles.flat_map { |article| article.article_tags.map(&:tag_id) }.compact.uniq
    @tag_sentiments = ArticleTag.sentiment_summary_for(tag_ids)
    @tag_lookup = {}
    @recent_articles.each do |article|
      article.article_tags.each do |article_tag|
        tag = article_tag.tag
        next unless tag

        @tag_lookup[tag.id] ||= tag
      end
    end
  end
end

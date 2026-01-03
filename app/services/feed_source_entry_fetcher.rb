# frozen_string_literal: true

require "rss"

class FeedSourceEntryFetcher
  Entry = Struct.new(:title, :url, :published_at, :text, keyword_init: true)

  DEFAULT_TIMEOUT = 10 # seconds
  USER_AGENT = "StatMachineFeedFetcher/1.0".freeze

  def initialize(feed_source, http_client: HTTParty, logger: Rails.logger)
    @feed_source = feed_source
    @http_client = http_client
    @logger = logger
  end

  def call
    mark_checked!
    body = fetch_feed_body
    return [] unless body

    entries = parse_entries(body)

    if entries.any?
      mark_imported!
      # OPTION A: Process immediately (Slow)
      # entries.each { |entry| FeedEntryProcessor.new(entry, feed_source).call }

      # OPTION B: Return entries to caller (Better Separation of Concerns)
      entries
    else
      []
    end
  end

  private

  attr_reader :feed_source, :http_client, :logger

  def fetch_feed_body
    response = http_client.get(feed_source.feed_url, request_options)
    return response.body if response.success?

    logger.warn("FeedSourceEntryFetcher: request failed for #{feed_source.feed_url} with status #{response.code}")
    nil
  rescue StandardError => e
    logger.error("FeedSourceEntryFetcher: error fetching #{feed_source.feed_url} - #{e.class}: #{e.message}")
    nil
  end

  def parse_entries(body)
    feed = RSS::Parser.parse(body, false)
    Array(feed&.items).filter_map { |item| build_entry(item) }
  rescue RSS::InvalidRSSError => e
    logger.error("FeedSourceEntryFetcher: invalid RSS for #{feed_source.feed_url} - #{e.message}")
    []
  end

  def build_entry(item)
    Entry.new(
      title: sanitize_title(item.title),
      url: extract_url(item),
      published_at: extract_published_at(item),
      text: extract_text(item)
    )
  end

  def sanitize_title(value)
    PlainTextSanitizer.call(value)
  end

  def extract_url(item)
    return unless item.respond_to?(:link)

    link = item.link
    link.respond_to?(:href) ? link.href : link
  end

  def extract_published_at(item)
    if item.respond_to?(:published)
      as_time(item.published.respond_to?(:content) ? item.published.content : item.published)
    elsif item.respond_to?(:updated)
      as_time(item.updated.respond_to?(:content) ? item.updated.content : item.updated)
    elsif item.respond_to?(:pubDate)
      item.pubDate
    end
  rescue ArgumentError
    nil
  end

  def extract_text(item)
    sanitized = full_sanitizer.sanitize(entry_body(item))
    sanitized.gsub(/\s+/, " ").strip
  end

  def entry_body(item)
    if item.respond_to?(:content_encoded) && item.content_encoded.present?
      item.content_encoded
    elsif item.respond_to?(:content)
      content = item.content
      content.respond_to?(:content) ? content.content : content
    elsif item.respond_to?(:summary)
      summary = item.summary
      summary.respond_to?(:content) ? summary.content : summary
    elsif item.respond_to?(:description)
      item.description
    else
      ""
    end
  end

  def full_sanitizer
    @full_sanitizer ||= ActionView::Base.full_sanitizer
  end

  def as_time(value)
    return value if value.is_a?(Time) || value.is_a?(DateTime)

    Time.zone.parse(value.to_s)
  end

  def request_options
    {
      headers: { "User-Agent" => USER_AGENT },
      timeout: DEFAULT_TIMEOUT
    }
  end

  def mark_checked!
    return unless feed_source&.persisted?

    feed_source.update_columns(last_checked_at: Time.current)
  rescue StandardError => e
    logger.warn("FeedSourceEntryFetcher: unable to update last_checked_at for #{feed_source.id} - #{e.message}")
  end

  def mark_imported!
    return unless feed_source&.persisted?

    feed_source.update_columns(last_imported_at: Time.current)
  rescue StandardError => e
    logger.warn("FeedSourceEntryFetcher: unable to update last_imported_at for #{feed_source.id} - #{e.message}")
  end
end

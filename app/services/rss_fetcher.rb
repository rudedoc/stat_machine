# frozen_string_literal: true

require "faraday"
require "rss"
require "cgi"

class RssFetcher
  DEFAULT_TIMEOUT = 10 # seconds

  class FetchError < StandardError; end
  class ParseError < StandardError; end

  def initialize(url, timeout: DEFAULT_TIMEOUT)
    @url = url
    @timeout = timeout
  end

  def call
    xml = fetch_xml
    parse(xml)
  end

  private

  def fetch_xml
    conn = Faraday.new do |f|
      f.options.timeout = @timeout
      f.options.open_timeout = @timeout
      f.adapter Faraday.default_adapter
    end

    response = conn.get(@url) do |req|
      # Some feeds behave better with a UA; Reddit generally works without,
      # but this reduces "bot" blocking risk.
      req.headers["User-Agent"] = "MyRailsAppRSSFetcher/1.0 (+https://example.com)"
      req.headers["Accept"] = "application/rss+xml, application/xml;q=0.9, */*;q=0.8"
    end

    unless response.success?
      raise FetchError, "HTTP #{response.status} fetching #{@url}"
    end

    response.body
  rescue Faraday::Error => e
    raise FetchError, "Failed to fetch #{@url}: #{e.class}: #{e.message}"
  end

  def parse(xml)
    RSS::Parser.parse(xml, false) # false = not validating (more tolerant)
  rescue StandardError => e
    raise ParseError, "Failed to parse RSS for #{@url}: #{e.class}: #{e.message}"
  end
end

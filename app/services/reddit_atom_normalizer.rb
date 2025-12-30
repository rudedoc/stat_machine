# frozen_string_literal: true

require "cgi"

module RedditAtomNormalizer
  module_function

  def normalize(entry)
    raw = entry.content&.content.to_s

    md_html = extract_md_div(strip_sc_markers(raw))
    safe_html = sanitize_html(md_html)
    plain_text = decode_entities(strip_html(md_html))

    {
      external_id: entry.id&.content,
      title: entry.title&.content&.strip,
      url: entry.link&.href,
      author: entry.author&.first&.name&.content,
      published_at: parse_time(entry.published&.content || entry.updated&.content),
      content_html: safe_html,
      content_text: plain_text
    }
  end

  def strip_sc_markers(html)
    html.to_s.gsub("<!-- SC_OFF -->", "").gsub("<!-- SC_ON -->", "").strip
  end

  def extract_md_div(html)
    html[/<div class="md">.*<\/div>/m].to_s
  end

  def sanitize_html(html)
    ActionController::Base.helpers.sanitize(
      html.to_s,
      tags: %w[p br strong em b i a ul ol li blockquote code pre h1 h2 h3 h4],
      attributes: %w[href]
    )
  end

  def strip_html(html)
    ActionView::Base.full_sanitizer.sanitize(html.to_s)
  end

  def decode_entities(text)
    CGI.unescapeHTML(text.to_s).gsub(/\s+/, " ").strip
  end

  def parse_time(str)
    return nil if str.blank?
    Time.zone.parse(str)
  rescue ArgumentError
    nil
  end
end

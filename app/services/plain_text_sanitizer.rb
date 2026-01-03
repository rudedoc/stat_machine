# frozen_string_literal: true

require "cgi"

# Converts HTML content into normalized plain text.
class PlainTextSanitizer
  class << self
    def call(value)
      text = value.to_s
      return if text.empty?

      sanitized = CGI.unescapeHTML(full_sanitizer.sanitize(text))
      normalized = sanitized.gsub(/\s+/, " ").strip
      normalized.empty? ? nil : normalized
    end

    private

    def full_sanitizer
      @full_sanitizer ||= ActionView::Base.full_sanitizer
    end
  end
end

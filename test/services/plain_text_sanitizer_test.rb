# frozen_string_literal: true

require "minitest/autorun"
require "action_view"

require_relative "../../app/services/plain_text_sanitizer"

class PlainTextSanitizerTest < Minitest::Test
  def test_removes_html_tags
    assert_equal "NBA Roundup", PlainTextSanitizer.call("<strong>NBA Roundup</strong>")
  end

  def test_decodes_entities_and_normalizes_whitespace
    input = "R&amp;D <em>Update</em>   2024"
    assert_equal "R&D Update 2024", PlainTextSanitizer.call(input)
  end

  def test_returns_nil_for_blank_values
    assert_nil PlainTextSanitizer.call(nil)
    assert_nil PlainTextSanitizer.call("   ")
  end
end

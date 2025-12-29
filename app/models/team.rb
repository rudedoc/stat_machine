class Team < ApplicationRecord
  has_many :sentiment_logs, dependent: :destroy

  # This method finds a team by name, short name, OR alias
  def self.identify(raw_text)
    clean_text = raw_text.to_s.downcase.strip
    return nil if clean_text.blank?

    # 1. Check the standard columns (Exact match)
    match = where("lower(name) = ? OR lower(short_name) = ?", clean_text, clean_text).first
    return match if match

    # 2. Check the Postgres Array (The "Smart" Search)
    # The syntax "? = ANY(aliases)" is specific to Postgres arrays.
    # It checks if 'clean_text' exists anywhere inside the array.
    where("? = ANY(aliases)", clean_text).first
  end
end
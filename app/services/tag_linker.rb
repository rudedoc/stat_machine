# frozen_string_literal: true

class TagLinker
  def self.link_competitor!(competitor)
    new.link_competitor!(competitor)
  end

  def self.link_tag!(tag)
    new.link_tag!(tag)
  end

  def link_competitor!(competitor)
    return unless competitor&.name.present?

    tag = Tag.identify(competitor.name, category: "team")
    return unless tag

    link_records(tag, competitor)
  end

  def link_tag!(tag)
    names = normalized_names(tag)
    return if names.empty?

    Competitor.includes(market: :event)
              .where("LOWER(competitors.name) IN (?)", names)
              .find_each do |competitor|
      link_records(tag, competitor)
    end
  end

  private

  def link_records(tag, competitor)
    link(tag, competitor)
    link(tag, competitor.market&.event)
  end

  def link(tag, taggable)
    return unless taggable&.persisted?

    Tagging.find_or_create_by!(tag: tag, taggable: taggable)
  rescue ActiveRecord::RecordNotUnique
    # Someone else linked it concurrently; safe to ignore
    nil
  end

  def normalized_names(tag)
    [ tag&.name, *Array(tag&.aliases) ].map { |value| value.to_s.downcase.strip }
                                     .reject(&:blank?).uniq
  end
end

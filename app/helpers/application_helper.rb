module ApplicationHelper
  TAG_CATEGORY_BADGE_CLASSES = {
    'team' => 'bg-primary bg-opacity-10 text-primary border border-primary border-opacity-25',
    'person' => 'bg-warning bg-opacity-10 text-warning border border-warning border-opacity-25',
    'competition' => 'bg-info bg-opacity-10 text-info border border-info border-opacity-25',
    'status' => 'bg-success bg-opacity-10 text-success border border-success border-opacity-25'
  }.freeze

  def tag_badge_class(tag)
    category_key = tag&.category.to_s.downcase
    TAG_CATEGORY_BADGE_CLASSES.fetch(category_key, 'bg-secondary bg-opacity-10 text-secondary border border-secondary border-opacity-25')
  end

  def tag_category_label(tag)
    label = tag&.category.to_s
    label.present? ? label.titleize : 'Tag'
  end
end

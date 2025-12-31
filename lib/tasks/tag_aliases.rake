namespace :tags do
  desc "Merge alias tags back into their canonical records"
  task deduplicate_aliases: :environment do
    merged = 0

    Tag.find_each do |tag|
      merged += tag.merge_duplicate_alias_records!
    end

    puts "Deduplicated #{merged} duplicate tag#{'s' unless merged == 1}."
  end
end

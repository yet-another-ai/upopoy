FactoryBot.define do
  factory :drive_item do
    association :project
    kind { "folder" }
    sequence(:name) { |index| "Folder #{index}" }

    trait :file do
      kind { "file" }
      sequence(:name) { |index| "document-#{index}.txt" }

      after(:build) do |drive_item|
        drive_item.file.attach(
          io: StringIO.new("Plain text"),
          filename: drive_item.name,
          content_type: "text/plain"
        )
      end
    end

    trait :markdown do
      kind { "file" }
      sequence(:name) { |index| "notes-#{index}.md" }
      text_content_cache { "# Notes\n\nInitial content" }

      after(:build) do |drive_item|
        drive_item.file.attach(
          io: StringIO.new(drive_item.text_content_cache),
          filename: drive_item.name,
          content_type: "text/markdown"
        )
      end
    end
  end
end

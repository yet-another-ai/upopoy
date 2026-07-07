FactoryBot.define do
  factory :project do
    sequence(:name) { |index| "Project #{index}" }
    description { "A focused project workspace." }
  end
end

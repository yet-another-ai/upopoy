FactoryBot.define do
  factory :project do
    association :user
    sequence(:name) { |index| "Project #{index}" }
    description { "A focused project workspace." }
  end
end

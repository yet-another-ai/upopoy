FactoryBot.define do
  factory :iteration do
    association :project
    sequence(:name) { |index| "Iteration #{index}" }
    starts_at { 1.week.from_now }
    deadline { 2.weeks.from_now }
    inbox { false }

    trait :inbox do
      name { "Inbox" }
      starts_at { nil }
      deadline { nil }
      inbox { true }
    end
  end
end

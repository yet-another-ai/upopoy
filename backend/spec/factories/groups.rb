FactoryBot.define do
  factory :group do
    sequence(:name) { |index| "Group #{index}" }
    description { "A collaborative workspace." }
  end
end

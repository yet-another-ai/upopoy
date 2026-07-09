FactoryBot.define do
  factory :organization do
    sequence(:name) { |index| "Organization #{index}" }
    description { "A collaborative workspace." }
  end
end

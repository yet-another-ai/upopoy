FactoryBot.define do
  factory :oauth_identity do
    association :user
    provider { "developer" }
    sequence(:uid) { |index| "developer-#{index}" }
  end
end

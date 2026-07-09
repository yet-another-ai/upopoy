FactoryBot.define do
  factory :chat_conversation do
    kind { "direct" }
    association :created_by, factory: :user

    trait :direct do
      kind { "direct" }
      sequence(:direct_key) { |index| "#{index}:#{index + 1000}" }
    end

    trait :channel do
      kind { "channel" }
      direct_key { nil }
      association :organization
    end

    trait :thread do
      kind { "thread" }
      direct_key { nil }
      association :parent_message, factory: :chat_message
    end
  end
end

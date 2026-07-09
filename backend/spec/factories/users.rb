FactoryBot.define do
  factory :user do
    sequence(:email) { |index| "user#{index}@example.com" }
    sequence(:display_name) { |index| "User #{index}" }
    title { "Contributor" }
    bio { "Keeps the work moving." }
    skills { [] }
    password { "password123" }
    password_confirmation { password }

    trait :system_admin do
      system_admin { true }
    end
  end
end

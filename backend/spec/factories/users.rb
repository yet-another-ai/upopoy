FactoryBot.define do
  factory :user do
    sequence(:email) { |index| "user#{index}@example.com" }
    sequence(:display_name) { |index| "User #{index}" }
    title { "Contributor" }
    bio { "Keeps the work moving." }
    password { "password123" }
    password_confirmation { password }
  end
end

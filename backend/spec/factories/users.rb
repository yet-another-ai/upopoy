FactoryBot.define do
  factory :user do
    sequence(:email) { |index| "user#{index}@example.com" }
    password { "password123" }
    password_confirmation { password }
  end
end

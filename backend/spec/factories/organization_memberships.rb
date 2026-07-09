FactoryBot.define do
  factory :organization_membership do
    association :organization
    association :user
    admin { false }

    trait :admin do
      admin { true }
    end
  end
end

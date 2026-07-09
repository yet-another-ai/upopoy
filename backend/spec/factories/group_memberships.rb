FactoryBot.define do
  factory :group_membership do
    association :group
    association :user
    admin { false }

    trait :admin do
      admin { true }
    end
  end
end

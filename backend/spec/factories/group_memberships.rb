FactoryBot.define do
  factory :group_membership do
    association :group
    association :user
    admin { true }
  end
end

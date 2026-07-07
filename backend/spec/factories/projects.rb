FactoryBot.define do
  factory :project do
    association :user
    association :group
    sequence(:name) { |index| "Project #{index}" }
    description { "A focused project workspace." }

    after(:create) do |project|
      next if GroupMembership.exists?(group: project.group, user: project.user)

      create(:group_membership, group: project.group, user: project.user)
    end
  end
end

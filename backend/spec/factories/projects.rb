FactoryBot.define do
  factory :project do
    association :user
    association :owner, factory: :organization
    sequence(:name) { |index| "Project #{index}" }
    description { "A focused project workspace." }

    trait :user_owned do
      owner { user }
    end

    after(:create) do |project|
      next unless project.owner.is_a?(Organization)
      next if OrganizationMembership.exists?(organization: project.owner, user: project.user)

      create(:organization_membership, :admin, organization: project.owner, user: project.user)
    end
  end
end

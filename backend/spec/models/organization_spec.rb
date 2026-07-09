require "rails_helper"

RSpec.describe Organization, type: :model do
  it "requires a name" do
    organization = build(:organization, name: "")

    expect(organization).not_to be_valid
    expect(organization.errors[:name]).to be_present
  end

  it "has users through memberships" do
    organization = create(:organization)
    user = create(:user)

    create(:organization_membership, organization:, user:)

    expect(organization.users).to contain_exactly(user)
    expect(user.organizations).to contain_exactly(organization)
  end

  it "owns projects polymorphically" do
    organization = create(:organization)
    project = create(:project, owner: organization)

    expect(organization.projects).to contain_exactly(project)
  end
end

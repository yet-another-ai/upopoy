require "rails_helper"

RSpec.describe OrganizationMembership, type: :model do
  it "defaults to a non-admin membership" do
    membership = described_class.new

    expect(membership).not_to be_admin
  end

  it "requires a unique user per organization" do
    membership = create(:organization_membership)
    duplicate = build(:organization_membership, organization: membership.organization, user: membership.user)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:user_id]).to be_present
  end

  it "does not allow the final organization admin to be demoted" do
    membership = create(:organization_membership, :admin)

    membership.admin = false

    expect(membership).not_to be_valid
    expect(membership.errors[:admin]).to be_present
  end

  it "does not allow the final organization admin membership to be destroyed" do
    membership = create(:organization_membership, :admin)

    expect(membership.destroy).to be(false)
    expect(membership.errors[:admin]).to be_present
  end

  it "allows an admin to be demoted when another direct admin remains" do
    membership = create(:organization_membership, :admin)
    create(:organization_membership, :admin, organization: membership.organization)

    membership.update!(admin: false)

    expect(membership).not_to be_admin
  end
end

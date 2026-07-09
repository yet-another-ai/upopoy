require "rails_helper"

RSpec.describe User, type: :model do
  it "creates a jti for JWT revocation" do
    user = create(:user)

    expect(user.jti).to be_present
  end

  it "requires a valid email" do
    user = build(:user, email: "invalid")

    expect(user).not_to be_valid
    expect(user.errors[:email]).to be_present
  end

  it "can belong to organizations through memberships" do
    user = create(:user)
    organization = create(:organization)

    create(:organization_membership, user:, organization:)

    expect(user.organizations).to contain_exactly(organization)
  end

  it "accesses organizations through direct memberships" do
    user = create(:user)
    organization = create(:organization)
    other = create(:organization)

    create(:organization_membership, user:, organization:)

    expect(user.accessible_organization_ids).to contain_exactly(organization.id)
    expect(user.can_access_organization?(organization.id)).to be(true)
    expect(user.can_access_organization?(other.id)).to be(false)
  end

  it "checks organization admin permissions through direct memberships" do
    user = create(:user)
    organization = create(:organization)
    other = create(:organization)
    create(:organization_membership, :admin, user:, organization:)

    expect(user.can_admin_organization?(organization.id)).to be(true)
    expect(user.can_admin_organization?(other.id)).to be(false)
  end

  it "memoizes adminable organization ids for repeated admin checks" do
    user = create(:user)
    organization = create(:organization)
    create(:organization_membership, :admin, user:, organization:)

    allow(OrganizationMembership).to receive(:adminable_organization_ids_for).and_call_original

    expect(user.can_admin_organization?(organization.id)).to be(true)
    expect(user.can_admin_organization?(organization.id)).to be(true)
    expect(OrganizationMembership).to have_received(:adminable_organization_ids_for).once
  end

  it "treats system admins as admins of every organization" do
    user = create(:user, :system_admin)
    organization = create(:organization)

    expect(user.can_access_organization?(organization.id)).to be(true)
    expect(user.can_admin_organization?(organization.id)).to be(true)
  end

  it "does not load organization ids when checking system admin organization access" do
    user = build_stubbed(:user, :system_admin)

    allow(Organization).to receive(:ids).and_call_original

    expect(user.can_access_organization?(1)).to be(true)
    expect(user.can_admin_organization?(1)).to be(true)
    expect(Organization).not_to have_received(:ids)
  end

  it "creates a user from an OmniAuth payload" do
    auth = OmniAuth::AuthHash.new(
      provider: "developer",
      uid: "42",
      info: { email: "oauth@example.com" }
    )

    user = described_class.from_omniauth(auth)

    expect(user.email).to eq("oauth@example.com")
    expect(user.oauth_identities.sole).to have_attributes(provider: "developer", uid: "42")
  end

  it "reuses an existing OAuth identity" do
    identity = create(:oauth_identity, provider: "developer", uid: "42")
    auth = OmniAuth::AuthHash.new(
      provider: "developer",
      uid: "42",
      info: { email: "oauth@example.com" }
    )

    expect(described_class.from_omniauth(auth)).to eq(identity.user)
  end
end

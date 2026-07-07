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

  it "can belong to groups through memberships" do
    user = create(:user)
    group = create(:group)

    create(:group_membership, user:, group:)

    expect(user.groups).to contain_exactly(group)
  end

  it "inherits access to descendant groups" do
    user = create(:user)
    parent = create(:group)
    child = create(:group, parent_group: parent)
    grandchild = create(:group, parent_group: child)

    create(:group_membership, user:, group: parent)

    expect(user.accessible_group_ids).to contain_exactly(parent.id, child.id, grandchild.id)
    expect(user.can_access_group?(grandchild.id)).to be(true)
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

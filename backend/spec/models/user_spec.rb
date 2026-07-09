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

  it "inherits group admin permissions to descendant groups" do
    user = create(:user)
    parent = create(:group)
    child = create(:group, parent_group: parent)
    create(:group_membership, :admin, user:, group: parent)

    expect(user.can_admin_group?(parent.id)).to be(true)
    expect(user.can_admin_group?(child.id)).to be(true)
  end

  it "memoizes adminable group ids for repeated admin checks" do
    user = create(:user)
    group = create(:group)
    create(:group_membership, :admin, user:, group:)

    allow(GroupHierarchy).to receive(:adminable_group_ids_for).and_call_original

    expect(user.can_admin_group?(group.id)).to be(true)
    expect(user.can_admin_group?(group.id)).to be(true)
    expect(GroupHierarchy).to have_received(:adminable_group_ids_for).once
  end

  it "treats system admins as admins of every group" do
    user = create(:user, :system_admin)
    group = create(:group)

    expect(user.can_access_group?(group.id)).to be(true)
    expect(user.can_admin_group?(group.id)).to be(true)
  end

  it "does not load group ids when checking system admin group access" do
    user = build_stubbed(:user, :system_admin)

    allow(Group).to receive(:ids).and_call_original

    expect(user.can_access_group?(1)).to be(true)
    expect(user.can_admin_group?(1)).to be(true)
    expect(Group).not_to have_received(:ids)
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

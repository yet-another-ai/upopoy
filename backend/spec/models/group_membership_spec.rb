require "rails_helper"

RSpec.describe GroupMembership, type: :model do
  it "defaults to a non-admin membership" do
    membership = described_class.new

    expect(membership).not_to be_admin
  end

  it "requires a unique user per group" do
    membership = create(:group_membership)
    duplicate = build(:group_membership, group: membership.group, user: membership.user)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:user_id]).to be_present
  end

  it "does not allow the final group admin to be demoted" do
    membership = create(:group_membership)

    membership.admin = false

    expect(membership).not_to be_valid
    expect(membership.errors[:admin]).to be_present
  end

  it "does not allow the final group admin membership to be destroyed" do
    membership = create(:group_membership)

    expect(membership.destroy).to be(false)
    expect(membership.errors[:admin]).to be_present
  end

  it "allows an admin to be demoted when another direct admin remains" do
    membership = create(:group_membership)
    create(:group_membership, group: membership.group)

    membership.update!(admin: false)

    expect(membership).not_to be_admin
  end
end

require "rails_helper"

RSpec.describe GroupMembership, type: :model do
  it "requires a unique user per group" do
    membership = create(:group_membership)
    duplicate = build(:group_membership, group: membership.group, user: membership.user)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:user_id]).to be_present
  end
end

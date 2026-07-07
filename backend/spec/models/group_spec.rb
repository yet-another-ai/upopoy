require "rails_helper"

RSpec.describe Group, type: :model do
  it "requires a name" do
    group = build(:group, name: "")

    expect(group).not_to be_valid
    expect(group.errors[:name]).to be_present
  end

  it "can have child groups" do
    parent = create(:group)
    child = create(:group, parent_group: parent)

    expect(parent.groups).to contain_exactly(child)
    expect(child.parent_group).to eq(parent)
  end

  it "can have users through memberships" do
    group = create(:group)
    user = create(:user)

    create(:group_membership, group:, user:)

    expect(group.users).to contain_exactly(user)
    expect(user.groups).to contain_exactly(group)
  end

  it "does not allow itself as a parent group" do
    group = create(:group)
    group.parent_group = group

    expect(group).not_to be_valid
    expect(group.errors[:parent_group]).to be_present
  end
end

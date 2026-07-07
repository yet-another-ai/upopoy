require "rails_helper"

RSpec.describe GroupHierarchy, type: :model do
  it "caches self and descendant group paths" do
    parent = create(:group)
    child = create(:group, parent_group: parent)
    grandchild = create(:group, parent_group: child)

    expect(described_class.pluck(:ancestor_group_id, :descendant_group_id, :depth)).to include(
      [ parent.id, parent.id, 0 ],
      [ parent.id, child.id, 1 ],
      [ parent.id, grandchild.id, 2 ]
    )
  end

  it "refreshes cached paths when a group moves" do
    first_parent = create(:group)
    second_parent = create(:group)
    child = create(:group, parent_group: first_parent)

    child.update!(parent_group: second_parent)

    expect(described_class.exists?(
      ancestor_group: first_parent,
      descendant_group: child
    )).to be(false)
    expect(described_class.exists?(
      ancestor_group: second_parent,
      descendant_group: child
    )).to be(true)
  end
end

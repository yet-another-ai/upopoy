class GroupHierarchy < ApplicationRecord
  belongs_to :ancestor_group, class_name: "Group"
  belongs_to :descendant_group, class_name: "Group"

  validates :ancestor_group_id, presence: true
  validates :descendant_group_id, presence: true
  validates :depth, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :ancestor_group_id, uniqueness: { scope: :descendant_group_id }

  def self.accessible_group_ids_for(user)
    joins(ancestor_group: :group_memberships)
      .where(group_memberships: { user_id: user.id })
      .distinct
      .select(:descendant_group_id)
  end

  def self.adminable_group_ids_for(user)
    joins(ancestor_group: :group_memberships)
      .where(group_memberships: { user_id: user.id, admin: true })
      .distinct
      .select(:descendant_group_id)
  end

  def self.rebuild!
    transaction do
      delete_all
      connection.execute <<~SQL.squish
        WITH RECURSIVE hierarchy AS (
          SELECT id AS ancestor_group_id, id AS descendant_group_id, 0 AS depth
          FROM groups
          UNION ALL
          SELECT hierarchy.ancestor_group_id, groups.id, hierarchy.depth + 1
          FROM hierarchy
          JOIN groups ON groups.parent_group_id = hierarchy.descendant_group_id
        )
        INSERT INTO group_hierarchies (
          ancestor_group_id,
          descendant_group_id,
          depth,
          created_at,
          updated_at
        )
        SELECT ancestor_group_id, descendant_group_id, depth, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        FROM hierarchy
      SQL
    end
  end
end

class CreateGroupHierarchies < ActiveRecord::Migration[8.1]
  def up
    create_table :group_hierarchies do |t|
      t.bigint :ancestor_group_id, null: false
      t.bigint :descendant_group_id, null: false
      t.integer :depth, null: false

      t.timestamps
    end

    add_index :group_hierarchies,
              [ :ancestor_group_id, :descendant_group_id ],
              unique: true,
              name: "index_group_hierarchies_on_ancestor_and_descendant"
    add_index :group_hierarchies, :descendant_group_id
    add_foreign_key :group_hierarchies, :groups, column: :ancestor_group_id, on_delete: :cascade
    add_foreign_key :group_hierarchies, :groups, column: :descendant_group_id, on_delete: :cascade

    rebuild_group_hierarchies
  end

  def down
    drop_table :group_hierarchies
  end

  private

  def rebuild_group_hierarchies
    execute <<~SQL.squish
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

class AddAdminToGroupMemberships < ActiveRecord::Migration[8.1]
  def up
    add_column :group_memberships, :admin, :boolean, null: false, default: false
    add_index :group_memberships, [ :group_id, :admin ]

    execute <<~SQL.squish
      UPDATE group_memberships
      SET admin = TRUE
    SQL

    execute <<~SQL.squish
      INSERT INTO group_memberships (group_id, user_id, admin, created_at, updated_at)
      SELECT groups.id, system_admins.id, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM groups
      CROSS JOIN LATERAL (
        SELECT users.id
        FROM users
        WHERE users.system_admin = TRUE
        ORDER BY users.id ASC
        LIMIT 1
      ) system_admins
      WHERE NOT EXISTS (
        SELECT 1
        FROM group_memberships
        WHERE group_memberships.group_id = groups.id
      )
    SQL
  end

  def down
    remove_index :group_memberships, [ :group_id, :admin ]
    remove_column :group_memberships, :admin
  end
end

class AddSoftDeleteToDriveItems < ActiveRecord::Migration[8.1]
  def change
    add_column :drive_items, :deleted_at, :datetime
    add_index :drive_items, :deleted_at

    remove_index :drive_items, name: "index_drive_items_on_project_root_name"
    remove_index :drive_items, name: "index_drive_items_on_project_parent_name"

    add_index :drive_items,
      "project_id, lower(name)",
      name: "index_drive_items_on_project_root_name",
      unique: true,
      where: "parent_id IS NULL AND deleted_at IS NULL"

    add_index :drive_items,
      "project_id, parent_id, lower(name)",
      name: "index_drive_items_on_project_parent_name",
      unique: true,
      where: "parent_id IS NOT NULL AND deleted_at IS NULL"
  end
end

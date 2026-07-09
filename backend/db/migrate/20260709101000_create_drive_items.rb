class CreateDriveItems < ActiveRecord::Migration[8.1]
  def change
    create_table :drive_items do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.references :parent, foreign_key: { to_table: :drive_items, on_delete: :cascade }
      t.string :kind, null: false
      t.string :name, null: false
      t.text :text_content_cache, default: "", null: false

      t.timestamps
    end

    add_index :drive_items,
      "project_id, lower(name)",
      name: "index_drive_items_on_project_root_name",
      unique: true,
      where: "parent_id IS NULL"

    add_index :drive_items,
      "project_id, parent_id, lower(name)",
      name: "index_drive_items_on_project_parent_name",
      unique: true,
      where: "parent_id IS NOT NULL"

    add_index :drive_items, [ :project_id, :kind ]
  end
end

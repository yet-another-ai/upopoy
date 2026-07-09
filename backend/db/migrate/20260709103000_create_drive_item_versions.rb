class CreateDriveItemVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :drive_item_versions do |t|
      t.references :drive_item, null: false, foreign_key: { on_delete: :cascade }
      t.integer :version_number, null: false
      t.string :name, null: false
      t.string :content_type
      t.bigint :byte_size
      t.text :text_content_cache, default: "", null: false

      t.timestamps
    end

    add_index :drive_item_versions, [ :drive_item_id, :version_number ], unique: true
  end
end

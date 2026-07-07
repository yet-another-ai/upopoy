class CreateGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :groups do |t|
      t.references :parent_group, foreign_key: { to_table: :groups, on_delete: :nullify }
      t.string :name, null: false
      t.text :description

      t.timestamps
    end

    create_table :group_memberships do |t|
      t.references :group, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :group_memberships, [ :group_id, :user_id ], unique: true
  end
end

class AddSystemAdminToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :system_admin, :boolean, null: false, default: false
  end
end

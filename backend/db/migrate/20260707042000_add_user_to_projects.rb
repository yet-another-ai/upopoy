class AddUserToProjects < ActiveRecord::Migration[8.1]
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  class MigrationProject < ActiveRecord::Base
    self.table_name = "projects"
  end

  def up
    add_reference :projects, :user, foreign_key: true

    assign_existing_projects

    change_column_null :projects, :user_id, false
  end

  def down
    remove_reference :projects, :user, foreign_key: true
  end

  private

  def assign_existing_projects
    return unless MigrationProject.where(user_id: nil).exists?

    owner = MigrationUser.first || MigrationUser.create!(
      email: "owner@upopoy.local",
      encrypted_password: "!",
      jti: SecureRandom.uuid,
      created_at: Time.current,
      updated_at: Time.current
    )

    MigrationProject.where(user_id: nil).update_all(user_id: owner.id, updated_at: Time.current)
  end
end

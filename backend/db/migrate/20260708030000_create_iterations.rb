class CreateIterations < ActiveRecord::Migration[8.1]
  class MigrationProject < ActiveRecord::Base
    self.table_name = "projects"
  end

  class MigrationIteration < ActiveRecord::Base
    self.table_name = "iterations"
  end

  def up
    create_table :iterations do |t|
      t.datetime :deadline
      t.boolean :inbox, default: false, null: false
      t.string :name, null: false
      t.bigint :project_id, null: false

      t.timestamps
    end

    add_index :iterations, :project_id
    add_index :iterations, [ :project_id, :inbox ], unique: true, where: "inbox = true"
    add_foreign_key :iterations, :projects, on_delete: :cascade

    add_reference :tasks, :iteration, foreign_key: { on_delete: :nullify }

    MigrationProject.find_each do |project|
      inbox = MigrationIteration.create!(
        project_id: project.id,
        name: "Inbox",
        inbox: true,
        created_at: Time.current,
        updated_at: Time.current
      )

      execute <<~SQL.squish
        UPDATE tasks
        SET iteration_id = #{inbox.id}
        WHERE project_id = #{project.id}
          AND iteration_id IS NULL
      SQL
    end
  end

  def down
    remove_reference :tasks, :iteration, foreign_key: true
    drop_table :iterations
  end
end

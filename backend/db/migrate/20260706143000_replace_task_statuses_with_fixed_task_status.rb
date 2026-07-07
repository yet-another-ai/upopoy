class ReplaceTaskStatusesWithFixedTaskStatus < ActiveRecord::Migration[8.1]
  class MigrationTask < ActiveRecord::Base
    self.table_name = "tasks"
  end

  class MigrationTaskStatus < ActiveRecord::Base
    self.table_name = "task_statuses"
  end

  FIXED_STATUSES = %w[todo in_progress under_review done].freeze

  def up
    add_column :tasks, :status, :string, null: false, default: "todo"
    add_index :tasks, [ :project_id, :status, :position ]

    MigrationTask.reset_column_information
    MigrationTaskStatus.reset_column_information

    MigrationTask.find_each do |task|
      task_status = MigrationTaskStatus.find_by(id: task.task_status_id)
      status = FIXED_STATUSES.include?(task_status&.slug) ? task_status.slug : "todo"
      task.update_columns(status: status)
    end

    remove_index :tasks, [ :task_status_id, :position ] if index_exists?(:tasks, [ :task_status_id, :position ])
    remove_reference :tasks, :task_status, foreign_key: true
    drop_table :task_statuses
  end

  def down
    create_table :task_statuses do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :position, null: false

      t.timestamps
    end

    add_index :task_statuses, [ :project_id, :slug ], unique: true
    add_index :task_statuses, [ :project_id, :position ]
    add_reference :tasks, :task_status, foreign_key: true
    add_index :tasks, [ :task_status_id, :position ]

    remove_index :tasks, [ :project_id, :status, :position ] if index_exists?(:tasks, [ :project_id, :status, :position ])
    remove_column :tasks, :status
  end
end

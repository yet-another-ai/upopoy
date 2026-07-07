class CreateTaskStatuses < ActiveRecord::Migration[8.1]
  def change
    create_table :task_statuses do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :position, null: false

      t.timestamps
    end

    add_index :task_statuses, [ :project_id, :slug ], unique: true
    add_index :task_statuses, [ :project_id, :position ]
    add_reference :tasks, :task_status, null: false, foreign_key: true
    add_index :tasks, [ :task_status_id, :position ]
  end
end

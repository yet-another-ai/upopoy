class CreateTaskDeveloperAndReviewerMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :task_developers, id: false do |t|
      t.bigint :task_id, null: false
      t.bigint :user_id, null: false
    end

    add_index :task_developers, [ :task_id, :user_id ], unique: true
    add_index :task_developers, :user_id
    add_foreign_key :task_developers, :tasks, on_delete: :cascade
    add_foreign_key :task_developers, :users, on_delete: :cascade

    create_table :task_reviewers, id: false do |t|
      t.bigint :task_id, null: false
      t.bigint :user_id, null: false
    end

    add_index :task_reviewers, [ :task_id, :user_id ], unique: true
    add_index :task_reviewers, :user_id
    add_foreign_key :task_reviewers, :tasks, on_delete: :cascade
    add_foreign_key :task_reviewers, :users, on_delete: :cascade
  end
end

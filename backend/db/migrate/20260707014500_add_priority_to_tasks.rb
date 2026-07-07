class AddPriorityToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :priority, :string, null: false, default: "medium"
  end
end

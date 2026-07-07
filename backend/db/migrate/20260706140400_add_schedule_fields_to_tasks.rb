class AddScheduleFieldsToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :deadline, :date
    add_column :tasks, :estimated_minutes, :integer
  end
end

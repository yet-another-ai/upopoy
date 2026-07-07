class ChangeTasksDeadlineToDatetime < ActiveRecord::Migration[8.1]
  def change
    change_column :tasks, :deadline, :datetime
  end
end

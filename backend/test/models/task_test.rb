require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "requires title, project, and task status" do
    task = Task.new

    assert_not task.valid?
    assert_includes task.errors[:title], "can't be blank"
    assert_includes task.errors[:project], "must exist"
    assert_includes task.errors[:task_status], "must exist"
  end

  test "defaults to first project status and next position" do
    task = projects(:one).tasks.create!(title: "Default task")

    assert_equal task_statuses(:one), task.task_status
    assert_equal 1, task.position
  end

  test "status must belong to the same project" do
    task = projects(:one).tasks.new(title: "Wrong status", task_status: task_statuses(:empty))

    assert_not task.valid?
    assert_includes task.errors[:task_status], "must belong to the same project"
  end
end

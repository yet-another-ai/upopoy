require "test_helper"

class TaskStatusTest < ActiveSupport::TestCase
  test "requires name and project" do
    task_status = TaskStatus.new

    assert_not task_status.valid?
    assert_includes task_status.errors[:name], "can't be blank"
    assert_includes task_status.errors[:project], "must exist"
  end

  test "generates slug and next position" do
    task_status = projects(:one).task_statuses.create!(name: "Ready for review")

    assert_equal "ready_for_review", task_status.slug
    assert_equal 3, task_status.position
  end

  test "requires unique slug per project" do
    task_status = projects(:one).task_statuses.new(name: "Todo again", slug: "todo")

    assert_not task_status.valid?
    assert_includes task_status.errors[:slug], "has already been taken"
  end
end

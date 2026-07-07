require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "requires a name" do
    project = Project.new(description: "Missing name")

    assert_not project.valid?
    assert_includes project.errors[:name], "can't be blank"
  end

  test "creates default task statuses" do
    project = Project.create!(name: "New workflow")

    assert_equal [ "To do", "In progress", "Done" ], project.task_statuses.ordered.pluck(:name)
  end

  test "destroys dependent statuses and tasks" do
    project = projects(:one)

    assert_difference("TaskStatus.count", -project.task_statuses.count) do
      assert_difference("Task.count", -project.tasks.count) do
        project.destroy!
      end
    end
  end
end

require "test_helper"

class ApiV1TasksControllerTest < ActionDispatch::IntegrationTest
  test "lists project tasks" do
    get api_v1_project_tasks_url(projects(:one))

    assert_response :success
    assert_equal projects(:one).tasks.count, response.parsed_body.length
  end

  test "creates a task" do
    assert_difference("Task.count", 1) do
      post api_v1_project_tasks_url(projects(:one)),
        params: { task: { title: "Create demo data", description: "Seed useful tasks" } },
        as: :json
    end

    assert_response :created
    assert_equal task_statuses(:one).id, response.parsed_body["task_status_id"]
  end

  test "updates task status and position" do
    task = tasks(:one)

    patch api_v1_task_url(task),
      params: { task: { task_status_id: task_statuses(:three).id, position: 2 } },
      as: :json

    assert_response :success
    assert_equal task_statuses(:three).id, response.parsed_body["task_status_id"]
    assert_equal 2, response.parsed_body["position"]
  end

  test "rejects task status from another project" do
    patch api_v1_task_url(tasks(:one)),
      params: { task: { task_status_id: task_statuses(:empty).id } },
      as: :json

    assert_response :unprocessable_entity
    assert_includes response.parsed_body["errors"]["task_status"], "Task status must belong to the same project"
  end

  test "destroys a task" do
    assert_difference("Task.count", -1) do
      delete api_v1_task_url(tasks(:one))
    end

    assert_response :no_content
  end
end

require "test_helper"

class ApiV1TaskStatusesControllerTest < ActionDispatch::IntegrationTest
  test "lists task statuses" do
    get api_v1_project_task_statuses_url(projects(:one))

    assert_response :success
    assert_equal [ "To do", "In progress", "Done" ], response.parsed_body.map { |status| status["name"] }
  end

  test "creates a task status" do
    assert_difference("TaskStatus.count", 1) do
      post api_v1_project_task_statuses_url(projects(:one)),
        params: { task_status: { name: "Review" } },
        as: :json
    end

    assert_response :created
    assert_equal "review", response.parsed_body["slug"]
  end

  test "updates a task status" do
    patch api_v1_task_status_url(task_statuses(:two)),
      params: { task_status: { name: "Doing", position: 4 } },
      as: :json

    assert_response :success
    assert_equal "Doing", response.parsed_body["name"]
    assert_equal 4, response.parsed_body["position"]
  end

  test "destroys an empty task status" do
    assert_difference("TaskStatus.count", -1) do
      delete api_v1_task_status_url(task_statuses(:empty))
    end

    assert_response :no_content
  end

  test "does not destroy a task status with tasks" do
    assert_no_difference("TaskStatus.count") do
      delete api_v1_task_status_url(task_statuses(:one))
    end

    assert_response :unprocessable_entity
  end
end

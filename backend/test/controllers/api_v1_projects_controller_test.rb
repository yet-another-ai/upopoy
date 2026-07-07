require "test_helper"

class ApiV1ProjectsControllerTest < ActionDispatch::IntegrationTest
  test "lists projects" do
    get api_v1_projects_url

    assert_response :success
    assert_equal Project.count, response.parsed_body.length
  end

  test "creates a project with default statuses" do
    assert_difference("Project.count", 1) do
      assert_difference("TaskStatus.count", 3) do
        post api_v1_projects_url,
          params: { project: { name: "Agent workflows", description: "Later AI work" } },
          as: :json
      end
    end

    assert_response :created
    assert_equal "Agent workflows", response.parsed_body["name"]
  end

  test "updates a project" do
    patch api_v1_project_url(projects(:one)),
      params: { project: { name: "Updated MVP" } },
      as: :json

    assert_response :success
    assert_equal "Updated MVP", response.parsed_body["name"]
  end

  test "destroys a project" do
    assert_difference("Project.count", -1) do
      delete api_v1_project_url(projects(:two))
    end

    assert_response :no_content
  end

  test "returns a configurable board" do
    get board_api_v1_project_url(projects(:one))

    assert_response :success
    statuses = response.parsed_body["statuses"]
    assert_equal [ "To do", "In progress", "Done" ], statuses.map { |status| status["name"] }
    assert_equal [ "Draft landing-free app shell" ], statuses.first["tasks"].map { |task| task["title"] }
  end
end

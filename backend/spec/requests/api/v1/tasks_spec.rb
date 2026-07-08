require "rails_helper"

RSpec.describe "Api::V1::Tasks", type: :request do
  def expect_task_role_payload(role, user)
    expect(json_response["#{role}_ids"]).to eq([ user.id ])
    expect(json_response[role.to_s.pluralize].pluck("display_name")).to eq([ user.display_name ])
  end

  def expect_task_detail_payload(task)
    expect(json_response).to include(
      "id" => task.id,
      "priority" => "low",
      "deadline" => "2026-07-20T10:30:00Z",
      "estimated_minutes" => 180
    )
  end

  def post_project_task(project, attributes, user: project.user)
    post "/api/v1/projects/#{project.id}/tasks",
         params: { task: attributes },
         headers: auth_headers_for(user)
  end

  def patch_task(task, attributes)
    patch "/api/v1/tasks/#{task.id}",
          params: { task: attributes },
          headers: auth_headers_for(task.project.user)
  end

  def create_task_with_role_users(**attributes)
    developer = create(:user, display_name: "Ada Developer")
    reviewer = create(:user, display_name: "Grace Reviewer")
    task = create(:task, **attributes)
    task.developers << developer
    task.reviewers << reviewer

    [ task, developer, reviewer ]
  end

  describe "GET /api/v1/projects/:project_id/tasks" do
    it "lists project tasks" do
      project = create(:project)
      create(:task, project:, title: "First task")
      member = create(:user)
      create(:group_membership, group: project.group, user: member)

      get "/api/v1/projects/#{project.id}/tasks", headers: auth_headers_for(member)

      expect(response).to have_http_status(:ok)
      expect(json_response.pluck("title")).to eq([ "First task" ])
    end

    it "lists tasks in descendant group projects" do
      user = create(:user)
      parent = create(:group)
      child = create(:group, parent_group: parent)
      create(:group_membership, user:, group: parent)
      project = create(:project, group: child)
      create(:task, project:, title: "Inherited task")

      get "/api/v1/projects/#{project.id}/tasks", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response.pluck("title")).to eq([ "Inherited task" ])
    end

    it "does not list another user's project tasks" do
      project = create(:project)

      get "/api/v1/projects/#{project.id}/tasks", headers: auth_headers_for(create(:user))

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/projects/:project_id/tasks" do
    let(:task_params) do
      {
        title: "Draft MCP API",
        description: "Keep resources clear.",
        status: "in_progress",
        priority: "high"
      }
    end

    it "creates a task in the requested status" do
      project = create(:project)
      member = create(:user)
      create(:group_membership, group: project.group, user: member)

      post_project_task(project, task_params, user: member)

      expect(response).to have_http_status(:created)
      expect(json_response.slice("title", "status", "priority", "iteration_name")).to eq(
        "title" => "Draft MCP API",
        "status" => "in_progress",
        "priority" => "high",
        "iteration_name" => "Inbox"
      )
    end

    it "creates a task in the selected iteration" do
      project = create(:project)
      iteration = create(:iteration, project:, name: "Sprint 1")

      post "/api/v1/projects/#{project.id}/tasks",
           params: { task: task_params.merge(iteration_id: iteration.id) },
           headers: auth_headers_for(project.user)

      expect(response).to have_http_status(:created)
      expect(json_response["iteration_id"]).to eq(iteration.id)
      expect(json_response["iteration_name"]).to eq("Sprint 1")
    end

    it "creates a task with developers and reviewers" do
      project = create(:project)
      developer = create(:user, display_name: "Ada Developer")
      reviewer = create(:user, display_name: "Grace Reviewer")
      role_params = { developer_ids: [ developer.id ], reviewer_ids: [ reviewer.id ] }

      post_project_task(project, task_params.merge(role_params))

      expect(response).to have_http_status(:created)
      expect_task_role_payload(:developer, developer)
      expect_task_role_payload(:reviewer, reviewer)
    end

    it "rejects unknown task role users" do
      project = create(:project)

      post "/api/v1/projects/#{project.id}/tasks",
           params: { task: task_params.merge(developer_ids: [ -1 ]) },
           headers: auth_headers_for(project.user)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response.dig("errors", "developer_ids")).to include(
        I18n.t("api.errors.include_unknown_users")
      )
    end

    it "rejects an iteration from another project" do
      project = create(:project)
      other_iteration = create(:iteration)

      post "/api/v1/projects/#{project.id}/tasks",
           params: { task: task_params.merge(iteration_id: other_iteration.id) },
           headers: auth_headers_for(project.user)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response.dig("errors", "iteration")).to include(
        "Iteration must belong to the task project"
      )
    end

    it "creates a task in a descendant group project" do
      user = create(:user)
      parent = create(:group)
      child = create(:group, parent_group: parent)
      create(:group_membership, user:, group: parent)
      project = create(:project, group: child)

      post "/api/v1/projects/#{project.id}/tasks",
           params: { task: task_params },
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:created)
      expect(json_response["title"]).to eq("Draft MCP API")
    end
  end

  describe "GET /api/v1/tasks/:id" do
    it "returns task detail fields" do
      task, developer, reviewer = create_task_with_role_users(
        deadline: Time.zone.parse("2026-07-20 10:30:00 UTC"),
        estimated_minutes: 180,
        priority: "low"
      )

      get "/api/v1/tasks/#{task.id}", headers: auth_headers_for(task.project.user)

      expect(response).to have_http_status(:ok)
      expect_task_detail_payload(task)
      expect_task_role_payload(:developer, developer)
      expect_task_role_payload(:reviewer, reviewer)
    end
  end

  describe "PATCH /api/v1/tasks/:id" do
    it "updates task status and position" do
      project = create(:project)
      task = create(:task, project:)
      member = create(:user)
      create(:group_membership, group: project.group, user: member)

      patch "/api/v1/tasks/#{task.id}",
            params: { task: { status: "done", position: 4 } },
            headers: auth_headers_for(member)

      expect(response).to have_http_status(:ok)
      expect(json_response["status"]).to eq("done")
      expect(json_response["position"]).to eq(4)
    end

    it "updates task schedule fields" do
      task = create(:task)

      patch "/api/v1/tasks/#{task.id}",
            params: { task: { deadline: "2026-07-31T15:45:00Z", estimated_minutes: 240 } },
            headers: auth_headers_for(task.project.user)

      expect(response).to have_http_status(:ok)
      expect(json_response["deadline"]).to eq("2026-07-31T15:45:00Z")
      expect(json_response["estimated_minutes"]).to eq(240)
    end

    it "updates task priority" do
      task = create(:task)

      patch "/api/v1/tasks/#{task.id}",
            params: { task: { priority: "high" } },
            headers: auth_headers_for(task.project.user)

      expect(response).to have_http_status(:ok)
      expect(json_response["priority"]).to eq("high")
    end

    it "updates task developers and reviewers" do
      task = create(:task)
      old_developer = create(:user)
      developer = create(:user, display_name: "Ada Developer")
      reviewer = create(:user, display_name: "Grace Reviewer")
      task.developers << old_developer
      role_params = { developer_ids: [ developer.id ], reviewer_ids: [ reviewer.id ] }

      patch_task(task, role_params)

      expect(response).to have_http_status(:ok)
      expect_task_role_payload(:developer, developer)
      expect_task_role_payload(:reviewer, reviewer)
    end
  end

  describe "DELETE /api/v1/tasks/:id" do
    it "deletes a task" do
      task = create(:task)
      member = create(:user)
      create(:group_membership, group: task.project.group, user: member)

      expect {
        delete "/api/v1/tasks/#{task.id}", headers: auth_headers_for(member)
      }.to change(Task, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end

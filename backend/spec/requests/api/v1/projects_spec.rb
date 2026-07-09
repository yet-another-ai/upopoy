require "rails_helper"

RSpec.describe "Api::V1::Projects", type: :request do
  describe "GET /api/v1/projects" do
    it "lists projects newest first" do
      user = create(:user)
      older = create(:project, user:, name: "Older")
      newer = create(:project, user:, name: "Newer")
      create(:project, name: "Other user's project")
      older.update!(created_at: 1.day.ago)
      newer.update!(created_at: Time.current)

      get "/api/v1/projects", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response.pluck("name")).to eq([ "Newer", "Older" ])
    end

    it "lists projects in descendant groups" do
      user = create(:user)
      parent = create(:group)
      child = create(:group, parent_group: parent)
      create(:group_membership, user:, group: parent)
      project = create(:project, group: child, name: "Child Board")

      get "/api/v1/projects", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response.pluck("id")).to include(project.id)
    end

    it "requires authentication" do
      get "/api/v1/projects"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/projects" do
    it "creates a project" do
      user = create(:user)
      group = create(:group)
      create(:group_membership, :admin, user:, group:)
      project_params = { name: "AI Ops", description: "Agent-managed work.", group_id: group.id }

      post "/api/v1/projects",
           params: { project: project_params },
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:created)
      expect(json_response["name"]).to eq("AI Ops")
      project = Project.find(json_response["id"])
      expect(project.user).to eq(user)
      expect(project.group).to eq(group)
    end

    it "does not create a project for ordinary group members" do
      user = create(:user)
      group = create(:group)
      create(:group_membership, user:, group:, admin: false)

      post "/api/v1/projects",
           params: { project: { name: "AI Ops", group_id: group.id } },
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end

    it "creates a project in a descendant group" do
      user = create(:user)
      parent = create(:group)
      child = create(:group, parent_group: parent)
      create(:group_membership, :admin, user:, group: parent)

      post "/api/v1/projects",
           params: { project: { name: "Inherited Ops", group_id: child.id } },
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:created)
      expect(Project.find(json_response["id"]).group).to eq(child)
    end

    it "allows system admins to create a project in any group" do
      user = create(:user, :system_admin)
      group = create(:group)

      post "/api/v1/projects",
           params: { project: { name: "System Ops", group_id: group.id } },
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:created)
      expect(Project.find(json_response["id"]).group).to eq(group)
    end

    it "does not create a project in a group the user does not belong to" do
      user = create(:user)
      group = create(:group)

      post "/api/v1/projects",
           params: { project: { name: "AI Ops", group_id: group.id } },
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/projects/:id" do
    it "returns a project" do
      project = create(:project)

      get "/api/v1/projects/#{project.id}", headers: auth_headers_for(project.user)

      expect(response).to have_http_status(:ok)
      expect(json_response["id"]).to eq(project.id)
    end

    it "returns another user's project when the requester is a group member" do
      project = create(:project)
      member = create(:user)
      create(:group_membership, group: project.group, user: member)

      get "/api/v1/projects/#{project.id}", headers: auth_headers_for(member)

      expect(response).to have_http_status(:ok)
      expect(json_response["id"]).to eq(project.id)
      expect(json_response["group_id"]).to eq(project.group_id)
    end

    it "returns a project when the requester belongs to an ancestor group" do
      user = create(:user)
      parent = create(:group)
      child = create(:group, parent_group: parent)
      create(:group_membership, user:, group: parent)
      project = create(:project, group: child)

      get "/api/v1/projects/#{project.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response["id"]).to eq(project.id)
    end

    it "does not return another user's project" do
      project = create(:project)

      get "/api/v1/projects/#{project.id}", headers: auth_headers_for(create(:user))

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/projects/:id" do
    it "updates project attributes" do
      project = create(:project)
      member = create(:user)
      create(:group_membership, :admin, group: project.group, user: member)

      patch "/api/v1/projects/#{project.id}",
            params: { project: { name: "Renamed" } },
            headers: auth_headers_for(member)

      expect(response).to have_http_status(:ok)
      expect(json_response["name"]).to eq("Renamed")
    end

    it "does not update project attributes for ordinary group members" do
      project = create(:project)
      member = create(:user)
      create(:group_membership, group: project.group, user: member, admin: false)

      patch "/api/v1/projects/#{project.id}",
            params: { project: { name: "Renamed" } },
            headers: auth_headers_for(member)

      expect(response).to have_http_status(:forbidden)
    end

    it "does not move a project to a group the requester cannot access" do
      project = create(:project)
      inaccessible_group = create(:group)

      patch "/api/v1/projects/#{project.id}",
            params: { project: { group_id: inaccessible_group.id } },
            headers: auth_headers_for(project.user)

      expect(response).to have_http_status(:forbidden)
      expect(project.reload.group).not_to eq(inaccessible_group)
    end
  end

  describe "DELETE /api/v1/projects/:id" do
    it "deletes a project" do
      project = create(:project)
      member = create(:user)
      create(:group_membership, :admin, group: project.group, user: member)

      expect {
        delete "/api/v1/projects/#{project.id}", headers: auth_headers_for(member)
      }.to change(Project, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "does not delete a project for ordinary group members" do
      project = create(:project)
      member = create(:user)
      create(:group_membership, group: project.group, user: member, admin: false)

      expect {
        delete "/api/v1/projects/#{project.id}", headers: auth_headers_for(member)
      }.not_to change(Project, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/projects/:id/board" do
    it "groups tasks by fixed statuses" do
      project = create(:project)
      create_board_tasks(project)

      get "/api/v1/projects/#{project.id}/board", headers: auth_headers_for(project.user)

      expect(response).to have_http_status(:ok)
      expect_board_response(project)
    end

    it "localizes status names from the Accept-Language header" do
      project = create(:project)

      get "/api/v1/projects/#{project.id}/board",
          headers: auth_headers_for(project.user).merge("Accept-Language" => "zh-CN")

      expect(response).to have_http_status(:ok)
      expect(json_response["statuses"].map { |status| status["name"] }).to eq(
        %w[待办 进行中 待评审 完成]
      )
    end
  end

  def create_board_tasks(project)
    iteration = create(:iteration, project:, name: "Sprint 1")

    create(:task, project:, iteration:, status: "todo", title: "Plan", position: 2)
    create(:task, project:, status: "in_progress", title: "Build", position: 1)
  end

  def expect_board_response(project)
    expect(json_response.dig("project", "id")).to eq(project.id)
    expect(json_response.dig("inbox_iteration", "name")).to eq("Inbox")
    expect(json_response["iterations"].pluck("name")).to include("Inbox", "Sprint 1")
    expect(json_response["statuses"].map { |status| status["slug"] }).to eq(%w[todo in_progress under_review done])
    expect(json_response["statuses"].first["tasks"].pluck("title")).to eq([ "Plan" ])
    expect(json_response["statuses"].first["tasks"].first["iteration_name"]).to eq("Sprint 1")
    expect(json_response["statuses"].second["tasks"].pluck("title")).to eq([ "Build" ])
    expect(json_response["statuses"].second["tasks"].first["iteration_name"]).to eq("Inbox")
  end
end

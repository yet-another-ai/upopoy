require "rails_helper"

RSpec.describe "Api::V1::Projects", type: :request do
  describe "GET /api/v1/projects" do
    it "lists user-owned and organization-owned projects newest first" do
      user = create(:user)
      organization = create(:organization)
      create(:organization_membership, user:, organization:)
      older = create(:project, :user_owned, user:, name: "Personal")
      newer = create(:project, user:, owner: organization, name: "Org")
      create(:project, :user_owned, name: "Private")
      older.update!(created_at: 1.day.ago)
      newer.update!(created_at: Time.current)

      get "/api/v1/projects", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response.pluck("name")).to eq(%w[Org Personal])
    end
  end

  describe "POST /api/v1/projects" do
    it "creates a user-owned project" do
      user = create(:user)

      post "/api/v1/projects",
        params: { project: { name: "Personal", owner_type: "User", owner_id: user.id } },
        headers: auth_headers_for(user)

      expect(response).to have_http_status(:created)
      project = Project.find(json_response["id"])
      expect(project.owner).to eq(user)
      expect(json_response.slice("owner_type", "owner_id", "owner_name")).to include(
        "owner_type" => "User",
        "owner_id" => user.id
      )
    end

    it "creates an organization-owned project for organization admins" do
      user = create(:user)
      organization = create(:organization)
      create(:organization_membership, :admin, user:, organization:)

      post "/api/v1/projects",
        params: { project: { name: "Org", owner_type: "Organization", owner_id: organization.id } },
        headers: auth_headers_for(user)

      expect(response).to have_http_status(:created)
      expect(Project.find(json_response["id"]).owner).to eq(organization)
    end

    it "does not create an organization-owned project for ordinary members" do
      user = create(:user)
      organization = create(:organization)
      create(:organization_membership, user:, organization:, admin: false)

      post "/api/v1/projects",
        params: { project: { name: "Org", owner_type: "Organization", owner_id: organization.id } },
        headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end

    it "does not create a user-owned project for another user" do
      user = create(:user)
      other = create(:user)

      post "/api/v1/projects",
        params: { project: { name: "Other", owner_type: "User", owner_id: other.id } },
        headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/projects/:id" do
    it "returns a user-owned project to its owner" do
      project = create(:project, :user_owned)

      get "/api/v1/projects/#{project.id}", headers: auth_headers_for(project.user)

      expect(response).to have_http_status(:ok)
      expect(json_response["id"]).to eq(project.id)
    end

    it "returns an organization-owned project to members" do
      project = create(:project)
      member = create(:user)
      create(:organization_membership, organization: project.owner, user: member)

      get "/api/v1/projects/#{project.id}", headers: auth_headers_for(member)

      expect(response).to have_http_status(:ok)
      expect(json_response["owner_type"]).to eq("Organization")
      expect(json_response["owner_id"]).to eq(project.owner_id)
    end

    it "does not return another user's personal project" do
      project = create(:project, :user_owned)

      get "/api/v1/projects/#{project.id}", headers: auth_headers_for(create(:user))

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/projects/:id" do
    it "updates a user-owned project for the owner" do
      project = create(:project, :user_owned)

      patch "/api/v1/projects/#{project.id}",
        params: { project: { name: "Renamed" } },
        headers: auth_headers_for(project.user)

      expect(response).to have_http_status(:ok)
      expect(json_response["name"]).to eq("Renamed")
    end

    it "moves a project to an organization the requester can admin" do
      project = create(:project, :user_owned)
      organization = create(:organization)
      create(:organization_membership, :admin, user: project.user, organization:)

      patch "/api/v1/projects/#{project.id}",
        params: { project: { owner_type: "Organization", owner_id: organization.id } },
        headers: auth_headers_for(project.user)

      expect(response).to have_http_status(:ok)
      expect(project.reload.owner).to eq(organization)
    end

    it "does not move a project to an organization the requester cannot admin" do
      project = create(:project, :user_owned)
      organization = create(:organization)

      patch "/api/v1/projects/#{project.id}",
        params: { project: { owner_type: "Organization", owner_id: organization.id } },
        headers: auth_headers_for(project.user)

      expect(response).to have_http_status(:forbidden)
      expect(project.reload.owner).not_to eq(organization)
    end
  end

  describe "DELETE /api/v1/projects/:id" do
    it "deletes a project for an organization admin" do
      project = create(:project)
      member = create(:user)
      create(:organization_membership, :admin, organization: project.owner, user: member)

      expect {
        delete "/api/v1/projects/#{project.id}", headers: auth_headers_for(member)
      }.to change(Project, :count).by(-1)
      expect(response).to have_http_status(:no_content)
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
  end
end

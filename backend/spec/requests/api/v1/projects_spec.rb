require "rails_helper"

RSpec.describe "Api::V1::Projects", type: :request do
  describe "GET /api/v1/projects" do
    it "lists projects newest first" do
      older = create(:project, name: "Older")
      newer = create(:project, name: "Newer")
      older.update!(created_at: 1.day.ago)
      newer.update!(created_at: Time.current)

      get "/api/v1/projects"

      expect(response).to have_http_status(:ok)
      expect(json_response.pluck("name")).to eq([ "Newer", "Older" ])
    end
  end

  describe "POST /api/v1/projects" do
    it "creates a project" do
      post "/api/v1/projects", params: { project: { name: "AI Ops", description: "Agent-managed work." } }

      expect(response).to have_http_status(:created)
      expect(json_response["name"]).to eq("AI Ops")
      expect(Project.find(json_response["id"])).to be_present
    end
  end

  describe "GET /api/v1/projects/:id" do
    it "returns a project" do
      project = create(:project)

      get "/api/v1/projects/#{project.id}"

      expect(response).to have_http_status(:ok)
      expect(json_response["id"]).to eq(project.id)
    end
  end

  describe "PATCH /api/v1/projects/:id" do
    it "updates project attributes" do
      project = create(:project)

      patch "/api/v1/projects/#{project.id}", params: { project: { name: "Renamed" } }

      expect(response).to have_http_status(:ok)
      expect(json_response["name"]).to eq("Renamed")
    end
  end

  describe "DELETE /api/v1/projects/:id" do
    it "deletes a project" do
      project = create(:project)

      expect {
        delete "/api/v1/projects/#{project.id}"
      }.to change(Project, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "GET /api/v1/projects/:id/board" do
    it "groups tasks by fixed statuses" do
      project = create(:project)
      create(:task, project:, status: "todo", title: "Plan", position: 2)
      create(:task, project:, status: "in_progress", title: "Build", position: 1)

      get "/api/v1/projects/#{project.id}/board"

      expect(response).to have_http_status(:ok)
      expect(json_response.dig("project", "id")).to eq(project.id)
      expect(json_response["statuses"].map { |status| status["slug"] }).to eq(
        %w[todo in_progress under_review done]
      )
      expect(json_response["statuses"].first["tasks"].pluck("title")).to eq([ "Plan" ])
      expect(json_response["statuses"].second["tasks"].pluck("title")).to eq([ "Build" ])
    end
  end
end

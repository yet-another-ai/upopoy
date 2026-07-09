require "rails_helper"

RSpec.describe "Api::V1::Iterations", type: :request do
  describe "GET /api/v1/projects/:project_id/iterations" do
    it "lists project iterations with inbox first" do
      project = create(:project)
      iteration = create(:iteration, project:, name: "Sprint 1")

      get "/api/v1/projects/#{project.id}/iterations", headers: auth_headers_for(project.user)

      expect(response).to have_http_status(:ok)
      expect(json_response.pluck("name")).to eq([ "Inbox", "Sprint 1" ])
      expect(json_response.second["id"]).to eq(iteration.id)
      expect(json_response.second["starts_at"]).to be_present
    end
  end

  describe "POST /api/v1/projects/:project_id/iterations" do
    it "creates an iteration with a start time and deadline" do
      project = create(:project)

      post_iteration(project, name: "Sprint 1")

      expect(response).to have_http_status(:created)
      expect_created_iteration
    end

    it "rejects an iteration without a start time" do
      project = create(:project)

      post "/api/v1/projects/#{project.id}/iterations",
           params: { iteration: { name: "Sprint 1", deadline: "2026-08-01T10:00:00Z" } },
           headers: auth_headers_for(project.user)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response.dig("errors", "starts_at")).to be_present
    end
  end

  describe "PATCH /api/v1/iterations/:id" do
    it "updates an iteration" do
      iteration = create(:iteration)

      patch_iteration(iteration)

      expect(response).to have_http_status(:ok)
      expect(json_response["name"]).to eq("Renamed")
      expect(json_response["starts_at"]).to eq("2026-08-01T10:00:00Z")
      expect(json_response["deadline"]).to eq("2026-08-08T10:00:00Z")
    end
  end

  def post_iteration(project, name:)
    post "/api/v1/projects/#{project.id}/iterations",
         params: iteration_params(name:, starts_at: "2026-07-25T10:00:00Z", deadline: "2026-08-01T10:00:00Z"),
         headers: auth_headers_for(project.user)
  end

  def patch_iteration(iteration)
    patch "/api/v1/iterations/#{iteration.id}",
          params: iteration_params(name: "Renamed", starts_at: "2026-08-01T10:00:00Z", deadline: "2026-08-08T10:00:00Z"),
          headers: auth_headers_for(iteration.project.user)
  end

  def iteration_params(name:, starts_at:, deadline:)
    {
      iteration: {
        name:,
        starts_at:,
        deadline:
      }
    }
  end

  def expect_created_iteration
    expect(json_response["name"]).to eq("Sprint 1")
    expect(json_response["starts_at"]).to eq("2026-07-25T10:00:00Z")
    expect(json_response["deadline"]).to eq("2026-08-01T10:00:00Z")
    expect(json_response["inbox"]).to be(false)
  end
end

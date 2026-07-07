require "rails_helper"

RSpec.describe "Api::V1::Tasks", type: :request do
  describe "GET /api/v1/projects/:project_id/tasks" do
    it "lists project tasks" do
      project = create(:project)
      create(:task, project:, title: "First task")

      get "/api/v1/projects/#{project.id}/tasks"

      expect(response).to have_http_status(:ok)
      expect(json_response.pluck("title")).to eq([ "First task" ])
    end
  end

  describe "POST /api/v1/projects/:project_id/tasks" do
    it "creates a task in the requested status" do
      project = create(:project)
      task_params = {
        title: "Draft MCP API",
        description: "Keep resources clear.",
        status: "in_progress",
        priority: "high"
      }

      post "/api/v1/projects/#{project.id}/tasks", params: { task: task_params }

      expect(response).to have_http_status(:created)
      expect(json_response["title"]).to eq("Draft MCP API")
      expect(json_response["status"]).to eq("in_progress")
      expect(json_response["priority"]).to eq("high")
    end
  end

  describe "GET /api/v1/tasks/:id" do
    it "returns task detail fields" do
      task = create(
        :task,
        deadline: Time.zone.parse("2026-07-20 10:30:00 UTC"),
        estimated_minutes: 180,
        priority: "low"
      )

      get "/api/v1/tasks/#{task.id}"

      expect(response).to have_http_status(:ok)
      expect(json_response["id"]).to eq(task.id)
      expect(json_response["priority"]).to eq("low")
      expect(json_response["deadline"]).to eq("2026-07-20T10:30:00Z")
      expect(json_response["estimated_minutes"]).to eq(180)
    end
  end

  describe "PATCH /api/v1/tasks/:id" do
    it "updates task status and position" do
      project = create(:project)
      task = create(:task, project:)

      patch "/api/v1/tasks/#{task.id}", params: { task: { status: "done", position: 4 } }

      expect(response).to have_http_status(:ok)
      expect(json_response["status"]).to eq("done")
      expect(json_response["position"]).to eq(4)
    end

    it "updates task schedule fields" do
      task = create(:task)

      patch "/api/v1/tasks/#{task.id}",
            params: { task: { deadline: "2026-07-31T15:45:00Z", estimated_minutes: 240 } }

      expect(response).to have_http_status(:ok)
      expect(json_response["deadline"]).to eq("2026-07-31T15:45:00Z")
      expect(json_response["estimated_minutes"]).to eq(240)
    end

    it "updates task priority" do
      task = create(:task)

      patch "/api/v1/tasks/#{task.id}", params: { task: { priority: "high" } }

      expect(response).to have_http_status(:ok)
      expect(json_response["priority"]).to eq("high")
    end
  end

  describe "DELETE /api/v1/tasks/:id" do
    it "deletes a task" do
      task = create(:task)

      expect {
        delete "/api/v1/tasks/#{task.id}"
      }.to change(Task, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end

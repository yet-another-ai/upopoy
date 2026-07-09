require "rails_helper"

RSpec.describe "Api::V1::Search", type: :request do
  def search_result_slugs(query, user, resource_type: nil)
    get "/api/v1/search",
      params: { q: query, type: resource_type }.compact,
      headers: auth_headers_for(user)

    expect(response).to have_http_status(:ok)
    json_response["results"].pluck("slug")
  end

  describe "GET /api/v1/search" do
    it "returns an empty result set for a blank query" do
      get "/api/v1/search", params: { q: "" }, headers: auth_headers_for

      expect(response).to have_http_status(:ok)
      expect(json_response["results"]).to eq([])
    end

    it "requires authentication" do
      get "/api/v1/search", params: { q: "anything" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "searches resources visible to the current user" do
      user = create(:user)
      group = create(:group)
      create(:group_membership, user:, group:)
      owner = create(:user)
      create(:group_membership, user: owner, group:)
      project = create(:project, user: owner, group:, name: "Apollo", description: "Moonshot roadmap")
      create(:project, name: "Other Apollo")

      get "/api/v1/search", params: { q: "Apollo" }, headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      slugs = json_response["results"].pluck("slug")
      expect(slugs).to include("project:#{project.id}")
      expect(slugs).not_to include(SearchDocument.find_by(title: "Other Apollo").resource_slug)
    end

    it "searches resources in descendant groups" do
      user = create(:user)
      parent = create(:group)
      child = create(:group, parent_group: parent)
      create(:group_membership, user:, group: parent)
      project = create(:project, group: child, name: "Nested Apollo")
      task = create(:task, project:, title: "Nested Apollo task")

      get "/api/v1/search", params: { q: "Nested Apollo" }, headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response["results"].pluck("slug")).to include(
        "project:#{project.id}",
        "task:#{task.id}"
      )
    end

    it "searches drive folders and files visible to the current user" do
      user = create(:user)
      group = create(:group)
      create(:group_membership, user:, group:)
      project = create(:project, group:)
      folder = create(:drive_item, project:, name: "Architecture")
      file = create(:drive_item, :file, project:, name: "Budget.xlsx")
      hidden_file = create(:drive_item, :file, name: "Budget hidden.xlsx")

      expect(search_result_slugs("Architecture", user)).to include("drive_item:#{folder.id}")
      expect(search_result_slugs("Budget", user, resource_type: "drive_item")).to include("drive_item:#{file.id}")
      expect(json_response["results"].pluck("slug")).not_to include("drive_item:#{hidden_file.id}")
    end

    it "includes global users and member groups for authenticated users" do
      user = create(:user)
      target = create(:user, display_name: "Ada Lovelace")
      group = create(:group, name: "Research Guild")
      hidden_group = create(:group, name: "Research Vault")
      create(:group_membership, user:, group:)

      get "/api/v1/search", params: { q: "Ada" }, headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response["results"].pluck("slug")).to include("user:#{target.id}")

      get "/api/v1/search", params: { q: "Research" }, headers: auth_headers_for(user)

      slugs = json_response["results"].pluck("slug")
      expect(slugs).to include("group:#{group.id}")
      expect(slugs).not_to include("group:#{hidden_group.id}")
    end

    it "orders exact slug matches first" do
      user = create(:user)
      task = create(:task, project: create(:project, user:), title: "Ordinary title")
      create(:task, project: task.project, title: "task:#{task.id} mentioned elsewhere")

      get "/api/v1/search", params: { q: "task:#{task.id}" }, headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response.dig("results", 0, "slug")).to eq("task:#{task.id}")
    end

    it "filters by resource type" do
      user = create(:user)
      project = create(:project, user:, name: "Launch")
      task = create(:task, project:, title: "Launch checklist")

      get "/api/v1/search", params: { q: "Launch", type: "task" }, headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response["results"].pluck("slug")).to eq([ "task:#{task.id}" ])
    end
  end
end

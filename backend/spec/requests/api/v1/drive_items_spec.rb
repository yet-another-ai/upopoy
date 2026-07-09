require "rails_helper"

RSpec.describe "Api::V1::DriveItems", type: :request do
  def expect_markdown_upload_response
    expect(response).to have_http_status(:created)
    expect(json_response).to include(
      "name" => "Guide.md",
      "markdown" => true,
      "text_content_cache" => "# Guide"
    )
  end

  def uploaded_file(filename, content, content_type = "text/markdown")
    file = Tempfile.new([ File.basename(filename, ".*"), File.extname(filename) ])
    file.write(content)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, content_type, original_filename: filename)
  end

  def expect_version_numbers(*numbers)
    expect(json_response.pluck("version_number")).to eq(numbers)
  end

  def expect_restored_markdown(drive_item, content, version_count)
    expect(response).to have_http_status(:ok)
    expect(drive_item.reload.markdown_content).to eq(content)
    expect(drive_item.versions.count).to eq(version_count)
  end

  describe "GET /api/v1/projects/:project_id/drive_items" do
    it "lists root folders and files for a project" do
      project = create(:project)
      create(:drive_item, project:, name: "Specs")
      create(:drive_item, :markdown, project:, name: "Readme.md")

      get "/api/v1/projects/#{project.id}/drive_items", headers: auth_headers_for(project.user)

      expect(response).to have_http_status(:ok)
      expect(json_response.pluck("name")).to eq([ "Specs", "Readme.md" ])
    end

    it "lists children for a folder" do
      project = create(:project)
      parent = create(:drive_item, project:, name: "Specs")
      create(:drive_item, :markdown, project:, parent:, name: "API.md")

      get "/api/v1/projects/#{project.id}/drive_items",
        params: { parent_id: parent.id },
        headers: auth_headers_for(project.user)

      expect(response).to have_http_status(:ok)
      expect(json_response.pluck("name")).to eq([ "API.md" ])
    end

    it "does not list inaccessible project files" do
      project = create(:project)

      get "/api/v1/projects/#{project.id}/drive_items", headers: auth_headers_for(create(:user))

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/projects/:project_id/drive_items" do
    it "creates a folder" do
      project = create(:project)

      post "/api/v1/projects/#{project.id}/drive_items",
        params: { drive_item: { kind: "folder", name: "Specs", base_version_number: nil } },
        headers: auth_headers_for(project.user)

      expect(response).to have_http_status(:created)
      expect(json_response.slice("kind", "name", "markdown")).to eq(
        "kind" => "folder",
        "name" => "Specs",
        "markdown" => false
      )
    end

    it "uploads a markdown file and caches its content" do
      project = create(:project)

      post "/api/v1/projects/#{project.id}/drive_items",
        params: {
          drive_item: {
            kind: "file",
            file: uploaded_file("Guide.md", "# Guide"),
            base_version_number: nil
          }
        },
        headers: auth_headers_for(project.user)

      expect_markdown_upload_response
      expect(DriveItem.find(json_response["id"]).versions.count).to eq(1)
    end

    it "creates a new markdown document" do
      project = create(:project)

      post "/api/v1/projects/#{project.id}/drive_items",
        params: { drive_item: { kind: "file", name: "Notes.md", content: "# Notes", base_version_number: nil } },
        headers: auth_headers_for(project.user)

      expect(response).to have_http_status(:created)
      expect(json_response["name"]).to eq("Notes.md")
      expect(DriveItem.find(json_response["id"]).markdown_content).to eq("# Notes")
      expect(DriveItem.find(json_response["id"]).versions.count).to eq(1)
    end

    it "rejects a parent from another project" do
      project = create(:project)
      other_parent = create(:drive_item)

      post "/api/v1/projects/#{project.id}/drive_items",
        params: { drive_item: { kind: "folder", name: "Nested", parent_id: other_parent.id } },
        headers: auth_headers_for(project.user)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response.dig("errors", "parent").join).to include("must belong to the same project")
    end

    it "rejects new drive items with a non-nil base version number" do
      project = create(:project)

      post "/api/v1/projects/#{project.id}/drive_items",
        params: { drive_item: { kind: "file", name: "Notes.md", content: "# Notes", base_version_number: 1 } },
        headers: auth_headers_for(project.user)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response.dig("errors", "base_version_number").join).to include("must be nil")
    end
  end

  describe "GET/PATCH /api/v1/drive_items/:id/content" do
    it "returns and updates markdown content" do
      drive_item = create(:drive_item, :markdown, name: "Plan.md", text_content_cache: "# Plan")

      get "/api/v1/drive_items/#{drive_item.id}/content", headers: auth_headers_for(drive_item.project.user)
      expect(response).to have_http_status(:ok)
      expect(json_response["content"]).to eq("# Plan")

      patch "/api/v1/drive_items/#{drive_item.id}/content",
        params: { drive_item: { content: "# Updated", base_version_number: nil } },
        headers: auth_headers_for(drive_item.project.user)

      expect(response).to have_http_status(:ok)
      expect(json_response["content"]).to eq("# Updated")
      expect(drive_item.reload.text_content_cache).to eq("# Updated")
      expect(drive_item.versions.count).to eq(1)
    end

    it "rejects markdown updates when the base version is stale" do
      drive_item = create(:drive_item, :markdown, name: "Plan.md", text_content_cache: "# Plan")
      drive_item.record_version!

      patch "/api/v1/drive_items/#{drive_item.id}/content",
        params: { drive_item: { content: "# Updated", base_version_number: nil } },
        headers: auth_headers_for(drive_item.project.user)

      expect(response).to have_http_status(:conflict)
      expect(json_response.dig("errors", "base_version_number").join).to include("current version 1")
    end

    it "rejects non-markdown files" do
      drive_item = create(:drive_item, :file)

      get "/api/v1/drive_items/#{drive_item.id}/content", headers: auth_headers_for(drive_item.project.user)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/drive_items/:id" do
    it "renames and moves an item" do
      project = create(:project)
      parent = create(:drive_item, project:, name: "Specs")
      drive_item = create(:drive_item, :markdown, project:, name: "Draft.md")

      patch "/api/v1/drive_items/#{drive_item.id}",
        params: { drive_item: { name: "Final.md", parent_id: parent.id } },
        headers: auth_headers_for(project.user)

      expect(response).to have_http_status(:ok)
      expect(json_response.slice("name", "parent_id")).to eq(
        "name" => "Final.md",
        "parent_id" => parent.id
      )
    end
  end

  describe "GET /api/v1/drive_items/:id/download" do
    it "redirects to the Active Storage blob" do
      drive_item = create(:drive_item, :file)

      get "/api/v1/drive_items/#{drive_item.id}/download", headers: auth_headers_for(drive_item.project.user)

      expect(response).to have_http_status(:found)
      expect(response.headers["Location"]).to include("/rails/active_storage/blobs/redirect/")
    end
  end

  describe "file versions" do
    it "lists, reads, downloads, and restores versions" do
      drive_item = create(:drive_item, :markdown, name: "Plan.md", text_content_cache: "# Plan")
      original_version = drive_item.record_version!

      patch "/api/v1/drive_items/#{drive_item.id}/content",
        params: { drive_item: { content: "# Updated", base_version_number: original_version.version_number } },
        headers: auth_headers_for(drive_item.project.user)

      get "/api/v1/drive_items/#{drive_item.id}/versions", headers: auth_headers_for(drive_item.project.user)
      expect_version_numbers(2, 1)

      get "/api/v1/drive_item_versions/#{original_version.id}/content", headers: auth_headers_for(drive_item.project.user)
      expect(json_response["content"]).to eq("# Plan")

      post "/api/v1/drive_item_versions/#{original_version.id}/restore", headers: auth_headers_for(drive_item.project.user)
      expect_restored_markdown(drive_item, "# Plan", 3)
    end

    it "uploads a new file version" do
      drive_item = create(:drive_item, :file, name: "Guide.txt")
      drive_item.record_version!

      patch "/api/v1/drive_items/#{drive_item.id}/file",
        params: { drive_item: { file: uploaded_file("Guide.txt", "Updated", "text/plain"), base_version_number: 1 } },
        headers: auth_headers_for(drive_item.project.user)

      expect(response).to have_http_status(:ok)
      expect(drive_item.reload.versions.count).to eq(2)
      expect(drive_item.file.download).to eq("Updated")
    end

    it "rejects file uploads when the base version is stale" do
      drive_item = create(:drive_item, :file, name: "Guide.txt")
      drive_item.record_version!

      patch "/api/v1/drive_items/#{drive_item.id}/file",
        params: { drive_item: { file: uploaded_file("Guide.txt", "Updated", "text/plain"), base_version_number: nil } },
        headers: auth_headers_for(drive_item.project.user)

      expect(response).to have_http_status(:conflict)
      expect(drive_item.reload.file.download).to eq("Plain text")
    end
  end

  describe "DELETE /api/v1/drive_items/:id" do
    it "recursively soft-deletes folders" do
      project = create(:project)
      parent = create(:drive_item, project:, name: "Specs")
      child = create(:drive_item, :markdown, project:, parent:, name: "API.md")

      delete "/api/v1/drive_items/#{parent.id}", headers: auth_headers_for(project.user)

      expect(response).to have_http_status(:no_content)
      expect(DriveItem.exists?(parent.id)).to be(false)
      expect(DriveItem.with_deleted.exists?(parent.id)).to be(true)
      expect(child.reload).to be_deleted
    end
  end
end

require "rails_helper"

RSpec.describe SearchDocument, type: :model do
  describe "resource indexing" do
    it "creates a project search document with owner visibility" do
      project = create(:project, name: "Apollo", description: "Moonshot roadmap")

      document = described_class.find_by!(resource_slug: "project:#{project.id}")
      expect(document).to have_attributes(
        resource_type: "project",
        title: "Apollo",
        content: "Moonshot roadmap",
        owner: project.owner,
        api_path: "/api/v1/projects/#{project.id}"
      )
      expect(document.metadata).to eq("owner_type" => "Organization", "owner_id" => project.owner_id)
    end

    it "indexes task owner visibility and metadata from the task project" do
      project = create(:project, :user_owned)
      task = create(:task, project:, title: "Draft MCP API", description: "Keep resources clear.")

      document = described_class.find_by!(resource_slug: "task:#{task.id}")
      expect(document.owner).to eq(project.owner)
      expect(document.metadata).to eq(
        "project_id" => project.id,
        "owner_type" => "User",
        "owner_id" => project.owner_id,
        "iteration_id" => task.iteration_id
      )
      expect(document.api_path).to eq("/api/v1/tasks/#{task.id}")
    end

    it "indexes global users and organization-owned organizations" do
      user = create(:user, email: "ada@example.com", display_name: "Ada Lovelace")
      organization = create(:organization, name: "Engineering")

      user_document = described_class.find_by!(resource_slug: "user:#{user.id}")
      organization_document = described_class.find_by!(resource_slug: "organization:#{organization.id}")

      expect(user_document.title).to eq("Ada Lovelace")
      expect(user_document.owner).to be_nil
      expect(organization_document.title).to eq("Engineering")
      expect(organization_document.owner).to eq(organization)
    end
  end

  describe ".visible_to" do
    it "returns documents for owned personal projects" do
      user = create(:user)
      visible_project = create(:project, :user_owned, user:, name: "Visible")
      hidden_project = create(:project, :user_owned, name: "Hidden")

      slugs = described_class.visible_to(user).pluck(:resource_slug)

      expect(slugs).to include("user:#{user.id}", "project:#{visible_project.id}")
      expect(slugs).not_to include("project:#{hidden_project.id}")
    end

    it "returns documents for organizations the user directly belongs to" do
      user = create(:user)
      visible_project = create(:project, name: "Visible")
      hidden_project = create(:project, name: "Hidden")
      create(:organization_membership, user:, organization: visible_project.owner)

      slugs = described_class.visible_to(user).pluck(:resource_slug)

      expect(slugs).to include("project:#{visible_project.id}")
      expect(slugs).not_to include("project:#{hidden_project.id}")
    end
  end
end

require "rails_helper"

RSpec.describe SearchDocument, type: :model do
  describe "resource indexing" do
    it "creates a project search document" do
      project = create(:project, name: "Apollo", description: "Moonshot roadmap")

      document = described_class.find_by!(resource_slug: "project:#{project.id}")
      expect(document).to have_attributes(
        resource_type: "project",
        title: "Apollo",
        content: "Moonshot roadmap",
        user_id: project.user_id,
        api_path: "/api/v1/projects/#{project.id}"
      )
    end

    it "updates a project search document" do
      project = create(:project, name: "Apollo", description: "Moonshot roadmap")
      document = described_class.find_by!(resource_slug: "project:#{project.id}")
      project.update!(name: "Artemis")

      expect(document.reload.title).to eq("Artemis")
    end

    it "deletes a project search document" do
      project = create(:project, name: "Apollo", description: "Moonshot roadmap")
      document = described_class.find_by!(resource_slug: "project:#{project.id}")
      project.destroy!

      expect(described_class.exists?(document.id)).to be(false)
    end

    it "indexes task ownership and metadata from the task project" do
      project = create(:project)
      task = create(:task, project:, title: "Draft MCP API", description: "Keep resources clear.")

      document = described_class.find_by!(resource_slug: "task:#{task.id}")
      expect(document.user_id).to eq(project.user_id)
      expect(document.metadata).to eq("project_id" => project.id)
      expect(document.api_path).to eq("/api/v1/tasks/#{task.id}")
    end

    it "indexes global users and groups without an owner" do
      user = create(:user, email: "ada@example.com", display_name: "Ada Lovelace")
      group = create(:group, name: "Engineering")

      user_document = described_class.find_by!(resource_slug: "user:#{user.id}")
      group_document = described_class.find_by!(resource_slug: "group:#{group.id}")

      expect(user_document.title).to eq("Ada Lovelace")
      expect(user_document.user_id).to be_nil
      expect(group_document.title).to eq("Engineering")
      expect(group_document.user_id).to be_nil
    end
  end
end

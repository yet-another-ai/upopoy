require "rails_helper"

RSpec.describe DriveItem, type: :model do
  def expect_drive_item_search_document(document, drive_item)
    expect(document).to have_attributes(
      resource_type: "drive_item",
      title: drive_item.name,
      content: drive_item.text_content_cache,
      owner_id: drive_item.project.owner_id,
      api_path: "/api/v1/drive_items/#{drive_item.id}"
    )
  end

  def expect_drive_item_search_indexed(drive_item, kind:, markdown:)
    document = SearchDocument.find_by!(resource_slug: "drive_item:#{drive_item.id}")
    expect_drive_item_search_document(document, drive_item)
    expect(document.metadata).to include(
      "project_id" => drive_item.project_id,
      "kind" => kind,
      "markdown" => markdown
    )
  end

  describe "validations" do
    it "requires files to have an attachment" do
      drive_item = build(:drive_item, kind: "file", name: "empty.txt")

      expect(drive_item).not_to be_valid
      expect(drive_item.errors[:file]).to include("must be attached")
    end

    it "keeps names unique within a folder" do
      project = create(:project)
      parent = create(:drive_item, project:, name: "Specs")
      create(:drive_item, :markdown, project:, parent:, name: "Guide.md")

      duplicate = build(:drive_item, :markdown, project:, parent:, name: "guide.md")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end

    it "rejects parents from another project" do
      parent = create(:drive_item)
      drive_item = build(:drive_item, parent:)

      expect(drive_item).not_to be_valid
      expect(drive_item.errors[:parent]).to include("must belong to the same project")
    end

    it "rejects file parents" do
      project = create(:project)
      parent = create(:drive_item, :file, project:)
      drive_item = build(:drive_item, project:, parent:)

      expect(drive_item).not_to be_valid
      expect(drive_item.errors[:parent]).to include("must be a folder")
    end

    it "rejects moving a folder under its descendant" do
      project = create(:project)
      parent = create(:drive_item, project:, name: "Parent")
      child = create(:drive_item, project:, parent:, name: "Child")

      parent.parent = child

      expect(parent).not_to be_valid
      expect(parent.errors[:parent]).to include("cannot be itself or one of its descendants")
    end
  end

  describe "markdown content" do
    it "stores markdown content in the attachment and search cache" do
      drive_item = build(:drive_item, kind: "file", name: "README.md")

      drive_item.attach_markdown_content!("# README")
      drive_item.save!
      version = drive_item.record_version!

      expect(drive_item).to be_markdown
      expect(drive_item.markdown_content).to eq("# README")
      expect(drive_item.text_content_cache).to eq("# README")
      expect(version.version_number).to eq(1)
    end
  end

  describe "soft deletion" do
    it "hides soft-deleted items and keeps the rows for recovery" do
      parent = create(:drive_item, name: "Specs")
      child = create(:drive_item, :markdown, project: parent.project, parent:, name: "API.md")

      parent.soft_delete!

      expect(described_class.exists?(parent.id)).to be(false)
      expect(described_class.with_deleted.exists?(parent.id)).to be(true)
      expect(child.reload).to be_deleted
    end

    it "allows reusing names from soft-deleted items" do
      drive_item = create(:drive_item, name: "Specs")
      drive_item.soft_delete!

      replacement = build(:drive_item, project: drive_item.project, name: "Specs")

      expect(replacement).to be_valid
    end
  end

  describe "search indexing" do
    it "indexes folders and files with organization visibility and metadata" do
      project = create(:project)
      folder = create(:drive_item, project:, name: "Architecture")
      file = create(:drive_item, :file, project:, name: "Budget.xlsx")
      markdown = create(:drive_item, :markdown, project:, name: "Roadmap.md", text_content_cache: "Launch plan")

      expect_drive_item_search_indexed(folder, kind: "folder", markdown: false)
      expect_drive_item_search_indexed(file, kind: "file", markdown: false)
      expect_drive_item_search_indexed(markdown, kind: "file", markdown: true)
    end
  end
end

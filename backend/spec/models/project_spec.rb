require "rails_helper"

RSpec.describe Project, type: :model do
  it "requires a name" do
    project = build(:project, name: "")

    expect(project).not_to be_valid
    expect(project.errors[:name]).to be_present
  end

  it "can be persisted without project-specific task statuses" do
    project = create(:project)

    expect(project).to be_persisted
    expect(project.tasks).to be_empty
  end
end

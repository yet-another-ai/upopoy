require "rails_helper"

RSpec.describe Project, type: :model do
  it "requires a name" do
    project = build(:project, name: "")

    expect(project).not_to be_valid
    expect(project.errors[:name]).to be_present
  end

  it "requires a user" do
    project = build(:project, user: nil)

    expect(project).not_to be_valid
    expect(project.errors[:user]).to be_present
  end

  it "requires an owner" do
    project = build(:project, owner: nil)

    expect(project).not_to be_valid
    expect(project.errors[:owner]).to be_present
  end

  it "can be owned by a user" do
    user = create(:user)
    project = create(:project, user:, owner: user)

    expect(project.owner).to eq(user)
  end

  it "can be owned by an organization" do
    organization = create(:organization)
    project = create(:project, owner: organization)

    expect(project.owner).to eq(organization)
  end

  it "can be persisted without project-specific task statuses" do
    project = create(:project)

    expect(project).to be_persisted
    expect(project.tasks).to be_empty
  end
end

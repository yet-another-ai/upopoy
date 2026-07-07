require "rails_helper"

RSpec.describe Task, type: :model do
  it "requires a title" do
    task = build(:task, title: "")

    expect(task).not_to be_valid
    expect(task.errors[:title]).to be_present
  end

  it "requires a project" do
    task = described_class.new(title: "Unscoped task")

    expect(task).not_to be_valid
    expect(task.errors[:project]).to be_present
  end

  it "uses todo by default" do
    project = create(:project)
    task = create(:task, project:, status: nil)

    expect(task.status).to eq("todo")
  end

  it "uses medium priority by default" do
    task = create(:task, priority: nil)

    expect(task.priority).to eq("medium")
  end

  it "assigns the project inbox iteration by default" do
    project = create(:project)
    task = create(:task, project:, iteration: nil)

    expect(task.iteration).to eq(project.inbox_iteration)
    expect(task.iteration).to be_inbox
  end

  it "requires the iteration to belong to the task project" do
    project = create(:project)
    other_iteration = create(:iteration)
    task = build(:task, project:, iteration: other_iteration)

    expect(task).not_to be_valid
    expect(task.errors[:iteration]).to include("must belong to the task project")
  end

  it "rejects an unknown status" do
    task = build(:task, status: "blocked")

    expect(task).not_to be_valid
    expect(task.errors[:status]).to be_present
  end

  it "rejects an unknown priority" do
    task = build(:task, priority: "urgent")

    expect(task).not_to be_valid
    expect(task.errors[:priority]).to be_present
  end

  it "rejects negative estimated minutes" do
    task = build(:task, estimated_minutes: -1)

    expect(task).not_to be_valid
    expect(task.errors[:estimated_minutes]).to be_present
  end
end

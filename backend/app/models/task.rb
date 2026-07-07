class Task < ApplicationRecord
  include SearchableResource

  STATUSES = {
    "todo" => "To Do",
    "in_progress" => "In Progress",
    "under_review" => "Under Review",
    "done" => "Done"
  }.freeze

  PRIORITIES = {
    "low" => "Low",
    "medium" => "Medium",
    "high" => "High"
  }.freeze

  search_index_attributes :project_id, :title, :description, :status, :priority

  belongs_to :project

  before_validation :assign_defaults

  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES.keys }
  validates :priority, presence: true, inclusion: { in: PRIORITIES.keys }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :estimated_minutes,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true

  scope :ordered, -> { order(:position, :created_at) }
  scope :in_status_order, lambda {
    order(Arel.sql(status_order_sql), :position, :created_at)
  }

  def self.status_options
    STATUSES.map.with_index do |(id, name), index|
      {
        id: id,
        name: name,
        slug: id,
        position: index
      }
    end
  end

  def self.status_order_sql
    cases = STATUSES.keys.map.with_index { |status, index| "WHEN '#{status}' THEN #{index}" }.join(" ")
    "CASE tasks.status #{cases} ELSE #{STATUSES.length} END"
  end

  def search_title
    title
  end

  def search_content
    [
      description,
      STATUSES[status],
      PRIORITIES[priority]
    ].compact.join("\n")
  end

  def search_owner_user_id
    project&.user_id
  end

  def search_metadata
    { project_id: project_id }
  end

  def search_api_path
    "/api/v1/tasks/#{id}"
  end

  private

  def assign_defaults
    self.status = "todo" if status.blank?
    self.priority = "medium" if priority.blank?
    self.position = next_position if position.nil? || (new_record? && position.zero?)
  end

  def next_position
    return 0 if project.blank? || status.blank?

    project.tasks.where(status: status).maximum(:position).to_i + 1
  end
end

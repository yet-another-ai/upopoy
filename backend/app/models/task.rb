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

  search_index_attributes :project_id, :iteration_id, :title, :description, :status, :priority

  belongs_to :project
  belongs_to :iteration, optional: true
  has_and_belongs_to_many :developers,
                          class_name: "User",
                          join_table: "task_developers",
                          association_foreign_key: "user_id"
  has_and_belongs_to_many :reviewers,
                          class_name: "User",
                          join_table: "task_reviewers",
                          association_foreign_key: "user_id"

  before_validation :assign_defaults

  validates :title, presence: true
  validates :iteration, presence: true, if: :project_persisted?
  validates :status, presence: true, inclusion: { in: STATUSES.keys }
  validates :priority, presence: true, inclusion: { in: PRIORITIES.keys }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :estimated_minutes,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true
  validate :iteration_belongs_to_project

  scope :ordered, -> { order(:position, :created_at) }
  scope :in_status_order, lambda {
    order(Arel.sql(status_order_sql), :position, :created_at)
  }

  def self.status_options
    STATUSES.keys.map.with_index do |id, index|
      {
        id: id,
        name: status_name(id),
        slug: id,
        position: index
      }
    end
  end

  def self.status_name(status)
    I18n.t("tasks.statuses.#{status}", default: STATUSES.fetch(status, status.to_s.humanize))
  end

  def self.priority_name(priority)
    I18n.t("tasks.priorities.#{priority}", default: PRIORITIES.fetch(priority, priority.to_s.humanize))
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
      iteration&.name,
      self.class.status_name(status),
      self.class.priority_name(priority)
    ].compact.join("\n")
  end

  def search_owner_user_id
    nil
  end

  def search_owner_group_id
    project&.group_id
  end

  def search_metadata
    { project_id: project_id, group_id: project&.group_id, iteration_id: iteration_id }
  end

  def search_api_path
    "/api/v1/tasks/#{id}"
  end

  private

  def assign_defaults
    self.iteration ||= project&.inbox_iteration if project_persisted?
    self.status = "todo" if status.blank?
    self.priority = "medium" if priority.blank?
    self.position = next_position if position.nil? || (new_record? && position.zero?)
  end

  def iteration_belongs_to_project
    return if iteration.blank? || project.blank? || iteration.project_id == project_id

    errors.add(:iteration, "must belong to the task project")
  end

  def project_persisted?
    project&.persisted? || project_id.present?
  end

  def next_position
    return 0 if project.blank? || status.blank?

    project.tasks.where(status: status).maximum(:position).to_i + 1
  end
end

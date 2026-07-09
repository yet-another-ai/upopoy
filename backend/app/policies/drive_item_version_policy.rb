class DriveItemVersionPolicy < ApplicationPolicy
  def content?
    project_accessible?
  end

  def download?
    project_accessible?
  end

  def restore?
    project_accessible?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?

      project_ids = ProjectPolicy::Scope.new(user, Project).resolve.select(:id)
      scope.joins(:drive_item).where(drive_items: { project_id: project_ids })
    end
  end

  private

  def project_accessible?
    ProjectPolicy.new(user, record.drive_item&.project).show?
  end
end

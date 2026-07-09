class DriveItemVersionPolicy < ApplicationPolicy
  def content?
    project_group_member?
  end

  def download?
    project_group_member?
  end

  def restore?
    project_group_member?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?

      scope.joins(drive_item: :project).where(projects: { group_id: GroupHierarchy.accessible_group_ids_for(user) })
    end
  end

  private

  def project_group_member?
    return false if user.blank?

    group_id = record.drive_item&.project&.group_id
    user.can_access_group?(group_id)
  end
end

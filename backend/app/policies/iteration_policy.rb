class IterationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    project_group_member?
  end

  def create?
    project_group_member?
  end

  def update?
    project_group_member?
  end

  def destroy?
    project_group_member? && !record.inbox?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?

      scope.joins(:project).where(projects: { group_id: GroupHierarchy.accessible_group_ids_for(user) })
    end
  end

  private

  def project_group_member?
    return false if user.blank?

    group_id = record.project&.group_id
    user.can_access_group?(group_id)
  end
end

class TaskPolicy < ApplicationPolicy
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
    project_group_member?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?

      scope.joins(project: { group: :group_memberships })
        .where(group_memberships: { user_id: user.id })
    end
  end

  private

  def project_group_member?
    return false if user.blank?

    group_id = record.project&.group_id
    group_id.present? && user.group_ids.include?(group_id)
  end
end

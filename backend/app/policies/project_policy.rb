class ProjectPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    group_member?
  end

  def create?
    user.present? && record.user == user && group_admin?
  end

  def update?
    group_admin? && target_group_admin?
  end

  def destroy?
    group_admin?
  end

  def board?
    show?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?
      return scope.all if user.system_admin?

      scope.where(group_id: GroupHierarchy.accessible_group_ids_for(user))
    end
  end

  private

  def group_member?
    return false if user.blank? || record.group_id.blank?

    user.can_access_group?(record.group_id)
  end

  def group_admin?
    return false if user.blank?

    group_id = record.group_id_in_database || record.group_id
    group_id.present? && user.can_admin_group?(group_id)
  end

  def target_group_admin?
    record.group_id.present? && user.can_admin_group?(record.group_id)
  end
end

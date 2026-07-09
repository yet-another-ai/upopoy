class GroupPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    group_member?
  end

  def create?
    return false if user.blank?

    record.parent_group_id.blank? || user.can_admin_group?(record.parent_group_id)
  end

  def update?
    group_admin? && allowed_parent_group?
  end

  def destroy?
    group_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?
      return scope.all if user.system_admin?

      scope.where(id: GroupHierarchy.accessible_group_ids_for(user))
    end
  end

  private

  def group_member?
    user.present? && record.id.present? && user.can_access_group?(record.id)
  end

  def group_admin?
    user.present? && record.id.present? && user.can_admin_group?(record.id)
  end

  def allowed_parent_group?
    record.parent_group_id.blank? || user.can_admin_group?(record.parent_group_id)
  end
end

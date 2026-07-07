class GroupPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    group_member?
  end

  def create?
    return false if user.blank?

    record.parent_group_id.blank? || user.can_access_group?(record.parent_group_id)
  end

  def update?
    group_member? && allowed_parent_group?
  end

  def destroy?
    group_member?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?

      scope.where(id: GroupHierarchy.accessible_group_ids_for(user))
    end
  end

  private

  def group_member?
    user.present? && record.id.present? && user.can_access_group?(record.id)
  end

  def allowed_parent_group?
    record.parent_group_id.blank? || user.can_access_group?(record.parent_group_id)
  end
end

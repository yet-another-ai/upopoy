class ProjectPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    group_member?
  end

  def create?
    user.present? && record.user == user && group_member?
  end

  def update?
    group_member?
  end

  def destroy?
    group_member?
  end

  def board?
    show?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?

      scope.where(group_id: GroupHierarchy.accessible_group_ids_for(user))
    end
  end

  private

  def group_member?
    return false if user.blank? || record.group_id.blank?

    user.can_access_group?(record.group_id)
  end
end

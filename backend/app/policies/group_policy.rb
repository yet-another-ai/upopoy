class GroupPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    group_member?
  end

  def create?
    return false if user.blank?

    record.parent_group_id.blank? || user.group_ids.include?(record.parent_group_id)
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

      scope.joins(:group_memberships).where(group_memberships: { user_id: user.id })
    end
  end

  private

  def group_member?
    user.present? && record.id.present? && user.group_ids.include?(record.id)
  end

  def allowed_parent_group?
    record.parent_group_id.blank? || user.group_ids.include?(record.parent_group_id)
  end
end

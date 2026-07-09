class ChatChannelPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    group_member?
  end

  def create?
    group_admin?
  end

  def update?
    group_admin?
  end

  def destroy?
    group_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?

      group_ids = user.system_admin? ? Group.select(:id) : GroupHierarchy.accessible_group_ids_for(user)
      scope.where(group_id: group_ids)
    end
  end

  private

  def group_member?
    user.present? && record.group_id.present? && user.can_access_group?(record.group_id)
  end

  def group_admin?
    user.present? && record.group_id.present? && user.can_admin_group?(record.group_id)
  end
end

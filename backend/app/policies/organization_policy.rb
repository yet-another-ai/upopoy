class OrganizationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    organization_member?
  end

  def create?
    user.present?
  end

  def update?
    organization_admin?
  end

  def destroy?
    organization_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?
      return scope.all if user.system_admin?

      scope.where(id: OrganizationMembership.accessible_organization_ids_for(user))
    end
  end

  private

  def organization_member?
    user.present? && record.id.present? && user.can_access_organization?(record.id)
  end

  def organization_admin?
    user.present? && record.id.present? && user.can_admin_organization?(record.id)
  end
end

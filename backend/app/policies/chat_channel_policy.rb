class ChatChannelPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    organization_member?
  end

  def create?
    organization_admin?
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

      organization_ids = user.system_admin? ? Organization.select(:id) : OrganizationMembership.accessible_organization_ids_for(user)
      scope.where(organization_id: organization_ids)
    end
  end

  private

  def organization_member?
    user.present? && record.organization_id.present? && user.can_access_organization?(record.organization_id)
  end

  def organization_admin?
    user.present? && record.organization_id.present? && user.can_admin_organization?(record.organization_id)
  end
end

class ProjectPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    project_accessible?
  end

  def create?
    return false if user.blank? || record.user != user

    case record.owner
    when User
      record.owner == user || user.system_admin?
    when Organization
      user.can_admin_organization?(record.owner_id)
    else
      false
    end
  end

  def update?
    project_manageable? && target_owner_manageable?
  end

  def destroy?
    project_manageable?
  end

  def board?
    show?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?
      return scope.all if user.system_admin?

      scope
        .where(owner: user)
        .or(scope.where(owner_type: "Organization", owner_id: OrganizationMembership.accessible_organization_ids_for(user)))
    end
  end

  private

  def project_accessible?
    return false if user.blank?

    case record.owner
    when User
      record.owner == user || user.system_admin?
    when Organization
      user.can_access_organization?(record.owner_id)
    else
      false
    end
  end

  def project_manageable?
    return false if user.blank?

    owner_type = record.owner_type_in_database || record.owner_type
    owner_id = record.owner_id_in_database || record.owner_id

    case owner_type
    when "User"
      owner_id == user.id || user.system_admin?
    when "Organization"
      user.can_admin_organization?(owner_id)
    else
      false
    end
  end

  def target_owner_manageable?
    case record.owner
    when User
      record.owner == user || user.system_admin?
    when Organization
      user.can_admin_organization?(record.owner_id)
    else
      false
    end
  end
end

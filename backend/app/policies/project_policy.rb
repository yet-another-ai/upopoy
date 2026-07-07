class ProjectPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    owns_project?
  end

  def create?
    user.present? && record.user == user
  end

  def update?
    owns_project?
  end

  def destroy?
    owns_project?
  end

  def board?
    show?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?

      scope.where(user:)
    end
  end

  private

  def owns_project?
    user.present? && record.user_id == user.id
  end
end

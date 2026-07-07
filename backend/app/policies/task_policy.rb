class TaskPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    owns_task_project?
  end

  def create?
    owns_task_project?
  end

  def update?
    owns_task_project?
  end

  def destroy?
    owns_task_project?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?

      scope.joins(:project).where(projects: { user_id: user.id })
    end
  end

  private

  def owns_task_project?
    user.present? && record.project&.user_id == user.id
  end
end

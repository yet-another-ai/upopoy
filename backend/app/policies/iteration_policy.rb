class IterationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    project_accessible?
  end

  def create?
    project_accessible?
  end

  def update?
    project_accessible?
  end

  def destroy?
    project_accessible? && !record.inbox?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?

      project_ids = ProjectPolicy::Scope.new(user, Project).resolve.select(:id)
      scope.where(project_id: project_ids)
    end
  end

  private

  def project_accessible?
    ProjectPolicy.new(user, record.project).show?
  end
end

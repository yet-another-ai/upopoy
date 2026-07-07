class UserPolicy < ApplicationPolicy
  def show?
    user.present? && record.id == user.id
  end
end

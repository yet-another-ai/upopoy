class ApplicationSettingPolicy < ApplicationPolicy
  def show?
    user.present?
  end

  def update?
    user.present?
  end
end

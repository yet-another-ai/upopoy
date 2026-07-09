class ApplicationSettingPolicy < ApplicationPolicy
  def show?
    user.present?
  end

  def update?
    user&.system_admin?
  end
end

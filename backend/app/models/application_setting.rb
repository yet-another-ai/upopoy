class ApplicationSetting < ApplicationRecord
  validates :registration_enabled, inclusion: { in: [ true, false ] }
  validates :email_login_enabled, inclusion: { in: [ true, false ] }
  validates :singleton_guard, numericality: { only_integer: true, equal_to: 0 }

  def self.current
    first_or_create!(singleton_guard: 0)
  end
end

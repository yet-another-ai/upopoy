# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

require "securerandom"

root_admin_password = nil

User.transaction do
  unless User.lock.exists?(system_admin: true)
    root_admin_password = SecureRandom.urlsafe_base64(24)
    root_user = User.lock.find_or_initialize_by(email: "root@example.org")
    root_user.display_name = "Root Admin" if root_user.display_name.blank?
    root_user.assign_attributes(
      password: root_admin_password,
      password_confirmation: root_admin_password,
      system_admin: true
    )
    root_user.save!
  end
end

if root_admin_password
  puts <<~MESSAGE
    Created default system admin user:
      email: root@example.org
      password: #{root_admin_password}
  MESSAGE
end

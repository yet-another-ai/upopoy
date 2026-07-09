user_ids = organization.user_ids
admin_user_ids = organization.organization_memberships.filter_map { |membership| membership.user_id if membership.admin? }

json.extract! organization, :id, :name, :description, :created_at, :updated_at
json.user_ids user_ids
json.users_count user_ids.size
json.admin_user_ids admin_user_ids
json.admins_count admin_user_ids.size
json.can_admin viewer.can_admin_organization?(organization.id)

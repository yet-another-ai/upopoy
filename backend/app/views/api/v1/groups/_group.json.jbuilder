user_ids = group.user_ids
admin_user_ids = group.group_memberships.filter_map { |membership| membership.user_id if membership.admin? }
parent_group_visible = group.parent_group_id.present? && viewer.can_access_group?(group.parent_group_id)

json.extract! group, :id, :name, :description, :parent_group_id, :created_at, :updated_at
json.parent_group_name parent_group_visible ? group.parent_group&.name : nil
json.user_ids user_ids
json.users_count user_ids.size
json.admin_user_ids admin_user_ids
json.admins_count admin_user_ids.size
json.can_admin viewer.can_admin_group?(group.id)

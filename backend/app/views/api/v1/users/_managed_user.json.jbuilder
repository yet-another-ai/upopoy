json.partial! "api/v1/users/user", user: user
json.group_ids user.group_ids
json.groups_count user.group_ids.size

json.partial! "api/v1/users/user", user: user
json.organization_ids user.organization_ids
json.organizations_count user.organization_ids.size

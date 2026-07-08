json.users @users do |user|
  json.partial! "api/v1/users/managed_user", user: user
end

json.meta do
  json.partial! "api/v1/pagination/meta", paginated_users: @users
end

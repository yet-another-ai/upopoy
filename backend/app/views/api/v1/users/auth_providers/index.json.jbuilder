json.array! @auth_providers do |provider|
  json.name provider.fetch(:name)
  json.label provider.fetch(:label)
  json.authorize_path "/api/v1/auth/#{provider.fetch(:name)}"
end

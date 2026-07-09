json.array! @organizations do |organization|
  json.partial! "api/v1/organizations/organization", organization: organization, viewer: current_user
end

json.array! @groups do |group|
  json.partial! "api/v1/groups/group", group: group, viewer: current_user
end

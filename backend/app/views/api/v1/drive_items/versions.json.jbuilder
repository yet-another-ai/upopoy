json.array! @versions do |drive_item_version|
  json.partial! "api/v1/drive_item_versions/drive_item_version", drive_item_version: drive_item_version
end

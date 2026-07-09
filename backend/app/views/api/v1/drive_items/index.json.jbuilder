json.array! @drive_items do |drive_item|
  json.partial! "api/v1/drive_items/drive_item", drive_item: drive_item
end

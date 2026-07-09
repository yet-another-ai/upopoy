json.extract! drive_item,
  :id,
  :project_id,
  :parent_id,
  :kind,
  :name,
  :text_content_cache,
  :created_at,
  :updated_at
json.markdown drive_item.markdown?
json.content_type drive_item.content_type
json.byte_size drive_item.byte_size
json.download_path drive_item.file? ? "/api/v1/drive_items/#{drive_item.id}/download" : nil
json.deleted_at drive_item.deleted_at
json.versions_count drive_item.versions.size
json.latest_version_number drive_item.latest_version_number

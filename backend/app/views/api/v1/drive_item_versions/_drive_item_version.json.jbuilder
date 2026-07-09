json.extract! drive_item_version,
  :id,
  :drive_item_id,
  :version_number,
  :name,
  :content_type,
  :byte_size,
  :text_content_cache,
  :created_at,
  :updated_at
json.markdown drive_item_version.markdown?
json.download_path "/api/v1/drive_item_versions/#{drive_item_version.id}/download"

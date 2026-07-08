json.slug document.resource_slug
json.type document.resource_type
json.id document.searchable_id
json.title document.title
json.snippet document.content.to_s.truncate(160)
json.api_path document.api_path
json.metadata document.metadata
json.updated_at document.resource_updated_at

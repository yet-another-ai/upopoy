json.extract! project, :id, :group_id, :name, :description, :created_at, :updated_at
json.group_name project.group&.name

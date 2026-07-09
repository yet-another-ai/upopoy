json.extract! project, :id, :owner_type, :owner_id, :name, :description, :created_at, :updated_at
json.owner_name(
  case project.owner
  when User
    project.owner.display_name.presence || project.owner.email
  when Organization
    project.owner.name
  end
)

json.extract! task,
  :id,
  :project_id,
  :iteration_id,
  :status,
  :priority,
  :title,
  :description,
  :estimated_minutes,
  :position,
  :created_at,
  :updated_at
json.iteration_name task.iteration&.name
json.iteration_starts_at task.iteration&.starts_at&.iso8601
json.iteration_deadline task.iteration&.deadline&.iso8601
json.iteration_inbox task.iteration&.inbox?
json.deadline task.deadline&.iso8601
json.developer_ids task.developer_ids
json.developers task.developers do |developer|
  json.partial! "api/v1/users/user", user: developer
end
json.reviewer_ids task.reviewer_ids
json.reviewers task.reviewers do |reviewer|
  json.partial! "api/v1/users/user", user: reviewer
end

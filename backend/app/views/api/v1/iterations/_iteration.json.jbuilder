json.extract! iteration, :id, :project_id, :name, :created_at, :updated_at
json.starts_at iteration.starts_at&.iso8601
json.deadline iteration.deadline&.iso8601
json.inbox iteration.inbox?
json.task_count iteration.tasks.size

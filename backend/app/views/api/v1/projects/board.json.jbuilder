json.project do
  json.partial! "api/v1/projects/project", project: @project
end

json.iterations @iterations do |iteration|
  json.partial! "api/v1/iterations/iteration", iteration: iteration
end

json.inbox_iteration do
  json.partial! "api/v1/iterations/iteration", iteration: @inbox_iteration
end

json.statuses @status_options do |status|
  json.extract! status, :id, :name, :slug, :position
  json.tasks @tasks_by_status.fetch(status[:id], []) do |task|
    json.partial! "api/v1/tasks/task", task: task
  end
end

module Api
  module V1
    class BaseController < ApplicationController
      private

      def project_payload(project)
        {
          id: project.id,
          name: project.name,
          description: project.description,
          created_at: project.created_at,
          updated_at: project.updated_at
        }
      end

      def task_payload(task)
        {
          id: task.id,
          project_id: task.project_id,
          status: task.status,
          priority: task.priority,
          title: task.title,
          description: task.description,
          deadline: task.deadline&.iso8601,
          estimated_minutes: task.estimated_minutes,
          position: task.position,
          created_at: task.created_at,
          updated_at: task.updated_at
        }
      end

      def render_errors(record)
        render json: { errors: record.errors.to_hash(true) }, status: :unprocessable_entity
      end
    end
  end
end

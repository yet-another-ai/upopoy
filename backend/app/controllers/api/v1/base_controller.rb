module Api
  module V1
    class BaseController < ApplicationController
      include UserPayloads

      before_action :authenticate_user!
      after_action :verify_pundit_authorization

      private

      def verify_pundit_authorization
        if action_name == "index"
          verify_policy_scoped
        else
          verify_authorized
        end
      end

      def project_payload(project)
        {
          id: project.id,
          group_id: project.group_id,
          group_name: project.group&.name,
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

      def managed_user_payload(user)
        user_payload(user).merge(
          group_ids: user.group_ids,
          groups_count: user.group_ids.size
        )
      end

      def group_payload(group)
        user_ids = group.user_ids
        parent_group_visible = group.parent_group_id.present? &&
          current_user.group_ids.include?(group.parent_group_id)

        {
          id: group.id,
          name: group.name,
          description: group.description,
          parent_group_id: group.parent_group_id,
          parent_group_name: parent_group_visible ? group.parent_group&.name : nil,
          user_ids:,
          users_count: user_ids.size,
          created_at: group.created_at,
          updated_at: group.updated_at
        }
      end

      def pagination_payload(collection)
        {
          current_page: collection.current_page,
          total_pages: collection.total_pages,
          total_count: collection.total_count,
          per_page: collection.limit_value
        }
      end

      def render_errors(record)
        render json: { errors: record.errors.to_hash(true) }, status: :unprocessable_entity
      end
    end
  end
end

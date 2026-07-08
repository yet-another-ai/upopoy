module Api
  module V1
    class TasksController < BaseController
      before_action :set_project, only: [ :index, :create ]
      before_action :set_task, only: [ :show, :update, :destroy ]

      def index
        authorize Task
        tasks = policy_scope(@project.tasks)
          .includes(:developers, :iteration, :reviewers)
          .in_status_order

        render json: tasks.map { |task| task_payload(task) }
      end

      def create
        attributes = task_params
        developer_ids = normalize_user_ids(attributes.delete(:developer_ids))
        reviewer_ids = normalize_user_ids(attributes.delete(:reviewer_ids))
        task = @project.tasks.new(attributes)
        authorize task
        return render_invalid_user_ids(:developer_ids) unless valid_user_ids?(developer_ids)
        return render_invalid_user_ids(:reviewer_ids) unless valid_user_ids?(reviewer_ids)

        Task.transaction do
          task.save!
          task.developer_ids = developer_ids if developer_ids
          task.reviewer_ids = reviewer_ids if reviewer_ids
        end
        render json: task_payload(task.reload), status: :created
      rescue ActiveRecord::RecordInvalid
        render_errors(task)
      end

      def show
        authorize @task

        render json: task_payload(@task)
      end

      def update
        authorize @task
        attributes = task_params
        developer_ids = normalize_user_ids(attributes.delete(:developer_ids))
        reviewer_ids = normalize_user_ids(attributes.delete(:reviewer_ids))
        return render_invalid_user_ids(:developer_ids) unless valid_user_ids?(developer_ids)
        return render_invalid_user_ids(:reviewer_ids) unless valid_user_ids?(reviewer_ids)

        Task.transaction do
          @task.update!(attributes)
          @task.developer_ids = developer_ids if developer_ids
          @task.reviewer_ids = reviewer_ids if reviewer_ids
        end
        render json: task_payload(@task.reload)
      rescue ActiveRecord::RecordInvalid
        render_errors(@task)
      end

      def destroy
        authorize @task
        @task.destroy!

        head :no_content
      end

      private

      def set_project
        @project = policy_scope(Project).find(params[:project_id])
      end

      def set_task
        @task = policy_scope(Task).includes(:developers, :iteration, :reviewers).find(params[:id])
      end

      def task_params
        params.require(:task).permit(
          :status,
          :priority,
          :title,
          :description,
          :deadline,
          :estimated_minutes,
          :iteration_id,
          :position,
          developer_ids: [],
          reviewer_ids: []
        )
      end

      def normalize_user_ids(raw_user_ids)
        return nil if raw_user_ids.nil?

        raw_user_ids.filter_map do |user_id|
          next if user_id.blank?

          parsed_user_id = Integer(user_id, exception: false)
          return [ nil ] unless parsed_user_id

          parsed_user_id
        end.uniq
      end

      def valid_user_ids?(user_ids)
        return true if user_ids.nil?
        return false if user_ids.any?(&:nil?)

        known_user_ids = User.where(id: user_ids).pluck(:id)
        known_user_ids.sort == user_ids.sort
      end

      def render_invalid_user_ids(attribute)
        render json: { errors: { attribute => [ I18n.t("api.errors.include_unknown_users") ] } },
               status: :unprocessable_entity
      end
    end
  end
end

module Api
  module V1
    class TasksController < BaseController
      before_action :set_project, only: [ :index, :create ]
      before_action :set_task, only: [ :show, :update, :destroy ]

      def index
        authorize Task
        tasks = policy_scope(@project.tasks).in_status_order

        render json: tasks.map { |task| task_payload(task) }
      end

      def create
        task = @project.tasks.new(task_params)
        authorize task

        if task.save
          render json: task_payload(task), status: :created
        else
          render_errors(task)
        end
      end

      def show
        authorize @task

        render json: task_payload(@task)
      end

      def update
        authorize @task

        if @task.update(task_params)
          render json: task_payload(@task)
        else
          render_errors(@task)
        end
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
        @task = policy_scope(Task).find(params[:id])
      end

      def task_params
        params.require(:task).permit(
          :status,
          :priority,
          :title,
          :description,
          :deadline,
          :estimated_minutes,
          :position
        )
      end
    end
  end
end

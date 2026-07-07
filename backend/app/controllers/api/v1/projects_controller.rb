module Api
  module V1
    class ProjectsController < BaseController
      before_action :set_project, only: [ :show, :update, :destroy, :board ]

      def index
        projects = Project.order(created_at: :desc)

        render json: projects.map { |project| project_payload(project) }
      end

      def show
        render json: project_payload(@project)
      end

      def create
        project = Project.new(project_params)

        if project.save
          render json: project_payload(project), status: :created
        else
          render_errors(project)
        end
      end

      def update
        if @project.update(project_params)
          render json: project_payload(@project)
        else
          render_errors(@project)
        end
      end

      def destroy
        @project.destroy!

        head :no_content
      end

      def board
        tasks_by_status = @project.tasks.in_status_order.group_by(&:status)

        render json: {
          project: project_payload(@project),
          statuses: Task.status_options.map do |status|
            status.merge(
              tasks: tasks_by_status.fetch(status[:id], []).map { |task| task_payload(task) }
            )
          end
        }
      end

      private

      def set_project
        @project = Project.find(params[:id])
      end

      def project_params
        params.require(:project).permit(:name, :description)
      end
    end
  end
end

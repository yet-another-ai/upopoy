module Api
  module V1
    class ProjectsController < BaseController
      before_action :set_project, only: [ :show, :update, :destroy, :board ]

      def index
        projects = policy_scope(Project).order(created_at: :desc)

        render json: projects.map { |project| project_payload(project) }
      end

      def show
        authorize @project

        render json: project_payload(@project)
      end

      def create
        project = current_user.projects.new(project_params)
        authorize project

        if project.save
          render json: project_payload(project), status: :created
        else
          render_errors(project)
        end
      end

      def update
        @project.assign_attributes(project_params)
        authorize @project

        if @project.save
          render json: project_payload(@project)
        else
          render_errors(@project)
        end
      end

      def destroy
        authorize @project
        @project.destroy!

        head :no_content
      end

      def board
        authorize @project
        @project.inbox_iteration
        tasks_by_status = @project.tasks.includes(:iteration).in_status_order.group_by(&:status)
        iterations = @project.iterations.ordered.to_a

        render json: {
          project: project_payload(@project),
          iterations: iterations.map { |iteration| iteration_payload(iteration) },
          inbox_iteration: iteration_payload(iterations.find(&:inbox?)),
          statuses: Task.status_options.map do |status|
            status.merge(
              tasks: tasks_by_status.fetch(status[:id], []).map { |task| task_payload(task) }
            )
          end
        }
      end

      private

      def set_project
        @project = policy_scope(Project).find(params[:id])
      end

      def project_params
        params.require(:project).permit(:name, :description, :group_id)
      end
    end
  end
end

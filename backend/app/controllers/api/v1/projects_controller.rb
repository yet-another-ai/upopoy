module Api
  module V1
    class ProjectsController < BaseController
      before_action :set_project, only: [ :show, :update, :destroy, :board ]

      def index
        @projects = policy_scope(Project).includes(:owner).order(created_at: :desc)
      end

      def show
        authorize @project
      end

      def create
        project = current_user.projects.new(project_params)
        authorize project

        if project.save
          @project = project
          render :show, status: :created
        else
          render_errors(project)
        end
      end

      def update
        @project.assign_attributes(project_params)
        authorize @project

        if @project.save
          render :show
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
        @tasks_by_status = @project.tasks.includes(:developers, :iteration, :reviewers).in_status_order.group_by(&:status)
        @iterations = @project.iterations.ordered.to_a
        @inbox_iteration = @iterations.find(&:inbox?)
        @status_options = Task.status_options
      end

      private

      def set_project
        @project = policy_scope(Project).includes(:owner).find(params[:id])
      end

      def project_params
        params.require(:project).permit(:name, :description, :owner_type, :owner_id)
      end
    end
  end
end

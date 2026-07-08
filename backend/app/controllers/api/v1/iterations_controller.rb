module Api
  module V1
    class IterationsController < BaseController
      before_action :set_project, only: [ :index, :create ]
      before_action :set_iteration, only: [ :show, :update, :destroy ]

      def index
        authorize Iteration
        @iterations = policy_scope(@project.iterations).ordered
      end

      def show
        authorize @iteration
      end

      def create
        iteration = @project.iterations.new(iteration_params.merge(inbox: false))
        authorize iteration

        if iteration.save
          @iteration = iteration
          render :show, status: :created
        else
          render_errors(iteration)
        end
      end

      def update
        authorize @iteration

        if @iteration.update(iteration_params)
          render :show
        else
          render_errors(@iteration)
        end
      end

      def destroy
        authorize @iteration
        @iteration.tasks.update_all(iteration_id: @iteration.project.inbox_iteration.id)
        @iteration.destroy!

        head :no_content
      end

      private

      def set_project
        @project = policy_scope(Project).find(params[:project_id])
      end

      def set_iteration
        @iteration = policy_scope(Iteration).find(params[:id])
      end

      def iteration_params
        params.require(:iteration).permit(:name, :starts_at, :deadline)
      end
    end
  end
end

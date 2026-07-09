module Api
  module V1
    class UsersController < BaseController
      before_action :set_user, only: [ :show, :update ]

      def index
        @users = policy_scope(User)
          .includes(:organizations)
          .order(:email)
          .page(page_param)
          .per(per_page_param)
      end

      def show
        authorize @user
      end

      def update
        authorize @user

        if @user.update(user_params)
          @user.reload
          render :show
        else
          render_errors(@user)
        end
      end

      private

      def set_user
        @user = policy_scope(User).find(params[:id])
      end

      def user_params
        permitted_fields = [ :email, :display_name, :title, :bio ]
        permitted_fields << :system_admin if current_user.system_admin?

        params.require(:user).permit(*permitted_fields)
      end

      def page_param
        [ params.fetch(:page, 1).to_i, 1 ].max
      end

      def per_page_param
        params.fetch(:per_page, 10).to_i.clamp(1, 100)
      end
    end
  end
end

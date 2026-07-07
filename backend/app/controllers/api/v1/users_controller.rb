module Api
  module V1
    class UsersController < BaseController
      before_action :set_user, only: [ :show, :update ]

      def index
        users = policy_scope(User)
          .includes(:groups)
          .order(:email)
          .page(page_param)
          .per(per_page_param)

        render json: {
          users: users.map { |user| managed_user_payload(user) },
          meta: pagination_payload(users)
        }
      end

      def show
        authorize @user

        render json: managed_user_payload(@user)
      end

      def update
        authorize @user

        if @user.update(user_params)
          render json: managed_user_payload(@user.reload)
        else
          render_errors(@user)
        end
      end

      private

      def set_user
        @user = policy_scope(User).find(params[:id])
      end

      def user_params
        params.require(:user).permit(:email, :display_name, :title, :bio)
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

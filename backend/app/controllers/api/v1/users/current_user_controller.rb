module Api
  module V1
    module Users
      class CurrentUserController < BaseController
        before_action :authenticate_user!

        def show
          render json: { user: user_payload(current_user) }
        end
      end
    end
  end
end

module Api
  module V1
    module Users
      class CurrentUserController < BaseController
        def show
          authorize current_user

          render json: { user: user_payload(current_user) }
        end
      end
    end
  end
end

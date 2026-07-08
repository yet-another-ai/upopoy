module Api
  module V1
    module Users
      class CurrentUserController < BaseController
        def show
          authorize current_user
        end
      end
    end
  end
end

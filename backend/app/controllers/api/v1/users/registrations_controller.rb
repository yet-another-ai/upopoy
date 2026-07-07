module Api
  module V1
    module Users
      class RegistrationsController < Devise::RegistrationsController
        include UserPayloads

        respond_to :json

        def create
          build_resource(sign_up_params)

          if resource.save
            sign_in(resource_name, resource, store: false)
            render json: { user: user_payload(resource) }, status: :created
          else
            render json: { errors: resource.errors.to_hash(true) }, status: :unprocessable_entity
          end
        end

        private

        def sign_up_params
          params.require(:user).permit(:email, :password, :password_confirmation)
        end
      end
    end
  end
end

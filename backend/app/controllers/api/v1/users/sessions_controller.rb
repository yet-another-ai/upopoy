module Api
  module V1
    module Users
      class SessionsController < Devise::SessionsController
        include UserPayloads

        respond_to :json
        skip_before_action :verify_signed_out_user, only: :destroy

        def create
          unless ApplicationSetting.current.email_login_enabled?
            render json: { error: "Email login is disabled" }, status: :forbidden
            return
          end

          self.resource = warden.authenticate(auth_options)

          unless resource
            render json: { error: "Invalid email or password" }, status: :unauthorized
            return
          end

          sign_in(resource_name, resource, store: false)

          render json: { user: user_payload(resource) }, status: :ok
        end

        def destroy
          authenticate_user!

          render json: { message: "Signed out" }, status: :ok
        end
      end
    end
  end
end

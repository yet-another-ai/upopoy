module Api
  module V1
    module Users
      class SessionsController < Devise::SessionsController
        include LocalizesRequest
        include UserPayloads

        respond_to :json
        skip_before_action :verify_signed_out_user, only: :destroy

        def create
          unless ApplicationSetting.current.email_login_enabled?
            render json: { error: I18n.t("api.errors.email_login_disabled") }, status: :forbidden
            return
          end

          self.resource = warden.authenticate(auth_options)

          unless resource
            render json: { error: I18n.t("api.errors.invalid_email_or_password") },
                   status: :unauthorized
            return
          end

          sign_in(resource_name, resource, store: false)

          render json: { user: user_payload(resource) }, status: :ok
        end

        def destroy
          authenticate_user!

          render json: { message: I18n.t("api.messages.signed_out") }, status: :ok
        end
      end
    end
  end
end

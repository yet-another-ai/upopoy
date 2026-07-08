module Api
  module V1
    module Users
      class SessionsController < Devise::SessionsController
        include LocalizesRequest

        respond_to :json
        skip_before_action :verify_signed_out_user, only: :destroy

        def create
          unless ApplicationSetting.current.email_login_enabled?
            render "api/v1/errors/show",
              formats: :json,
              locals: { error: I18n.t("api.errors.email_login_disabled") },
              status: :forbidden
            return
          end

          self.resource = warden.authenticate(auth_options)

          unless resource
            render "api/v1/errors/show",
              formats: :json,
              locals: { error: I18n.t("api.errors.invalid_email_or_password") },
              status: :unauthorized
            return
          end

          sign_in(resource_name, resource, store: false)
        end

        def destroy
          authenticate_user!
        end
      end
    end
  end
end

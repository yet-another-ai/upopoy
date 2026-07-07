module Api
  module V1
    module Admin
      class SettingsController < BaseController
        def show
          settings = ApplicationSetting.current
          authorize settings

          render json: settings_payload(settings)
        end

        def update
          settings = ApplicationSetting.current
          authorize settings

          if settings.update(settings_params)
            render json: settings_payload(settings)
          else
            render_errors(settings)
          end
        end

        private

        def settings_params
          params.require(:settings).permit(:registration_enabled, :email_login_enabled)
        end

        def settings_payload(settings)
          {
            registration_enabled: settings.registration_enabled,
            email_login_enabled: settings.email_login_enabled,
            updated_at: settings.updated_at
          }
        end
      end
    end
  end
end

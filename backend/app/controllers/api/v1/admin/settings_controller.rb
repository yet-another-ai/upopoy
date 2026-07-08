module Api
  module V1
    module Admin
      class SettingsController < BaseController
        def show
          @settings = ApplicationSetting.current
          authorize @settings
        end

        def update
          @settings = ApplicationSetting.current
          authorize @settings

          if @settings.update(settings_params)
            render :show
          else
            render_errors(@settings)
          end
        end

        private

        def settings_params
          params.require(:settings).permit(:registration_enabled, :email_login_enabled)
        end
      end
    end
  end
end

module Api
  module V1
    class AuthSettingsController < ApplicationController
      def show
        render json: settings_payload(ApplicationSetting.current)
      end

      private

      def settings_payload(settings)
        {
          registration_enabled: settings.registration_enabled,
          email_login_enabled: settings.email_login_enabled
        }
      end
    end
  end
end

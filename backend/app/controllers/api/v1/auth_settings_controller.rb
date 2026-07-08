module Api
  module V1
    class AuthSettingsController < ApplicationController
      def show
        @settings = ApplicationSetting.current
      end
    end
  end
end

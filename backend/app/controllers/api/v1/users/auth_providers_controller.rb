module Api
  module V1
    module Users
      class AuthProvidersController < ApplicationController
        def index
          @auth_providers = Rails.application.config.x.auth_providers
        end
      end
    end
  end
end

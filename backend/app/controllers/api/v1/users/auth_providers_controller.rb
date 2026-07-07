module Api
  module V1
    module Users
      class AuthProvidersController < ApplicationController
        def index
          render json: Rails.application.config.x.auth_providers.map { |provider|
            {
              name: provider.fetch(:name),
              label: provider.fetch(:label),
              authorize_path: "/api/v1/auth/#{provider.fetch(:name)}"
            }
          }
        end
      end
    end
  end
end

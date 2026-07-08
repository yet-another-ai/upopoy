module Api
  module V1
    module Users
      class RegistrationsController < Devise::RegistrationsController
        include LocalizesRequest

        respond_to :json

        def create
          unless ApplicationSetting.current.registration_enabled?
            render "api/v1/errors/show",
              formats: :json,
              locals: { error: I18n.t("api.errors.registration_disabled") },
              status: :forbidden
            return
          end

          build_resource(sign_up_params)

          if resource.save
            sign_in(resource_name, resource, store: false)
            render :create, status: :created
          else
            render "api/v1/errors/show",
              formats: :json,
              locals: { errors: resource.errors.to_hash(true) },
              status: :unprocessable_entity
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

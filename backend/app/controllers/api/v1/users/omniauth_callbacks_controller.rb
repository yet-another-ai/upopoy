module Api
  module V1
    module Users
      class OmniauthCallbacksController < Devise::OmniauthCallbacksController
        include UserPayloads

        Rails.application.config.x.auth_provider_names.each do |provider|
          define_method(provider) { authenticate_provider }
        end

        def failure
          redirect_to frontend_callback_url(error: failure_message), allow_other_host: true
        end

        private

        def authenticate_provider
          user = User.from_omniauth(request.env.fetch("omniauth.auth"))
          token, = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)

          redirect_to frontend_callback_url(token:), allow_other_host: true
        rescue ActiveRecord::RecordInvalid => e
          redirect_to frontend_callback_url(error: e.record.errors.full_messages.to_sentence),
            allow_other_host: true
        end

        def frontend_callback_url(token: nil, error: nil)
          uri = URI(Rails.application.config.x.auth_frontend_callback_url)
          fragment_params = {}
          fragment_params[:token] = token if token.present?
          fragment_params[:error] = error if error.present?
          uri.fragment = fragment_params.to_query
          uri.to_s
        end
      end
    end
  end
end

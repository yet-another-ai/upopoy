module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_user!
      after_action :verify_pundit_authorization

      private

      def verify_pundit_authorization
        if action_name == "index"
          verify_policy_scoped
        else
          verify_authorized
        end
      end

      def render_errors(record)
        render "api/v1/errors/show",
          formats: :json,
          locals: { errors: record.errors.to_hash(true) },
          status: :unprocessable_entity
      end
    end
  end
end

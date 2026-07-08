class ApplicationController < ActionController::API
  include LocalizesRequest
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    render json: { error: I18n.t("api.errors.forbidden") }, status: :forbidden
  end
end

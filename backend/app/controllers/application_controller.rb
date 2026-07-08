class ApplicationController < ActionController::API
  include LocalizesRequest
  include Pundit::Authorization

  before_action :default_json_format
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def default_json_format
    request.format = :json if request.format.html?
  end

  def user_not_authorized
    render "api/v1/errors/show",
      formats: :json,
      locals: { error: I18n.t("api.errors.forbidden") },
      status: :forbidden
  end
end

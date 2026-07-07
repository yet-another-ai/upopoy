require "rails_helper"

RSpec.describe "Api::V1::Admin::Settings", type: :request do
  describe "GET /api/v1/admin/settings" do
    it "returns settings for authenticated users" do
      user = create(:user)
      ApplicationSetting.current.update!(registration_enabled: false)

      get "/api/v1/admin/settings", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response).to include(
        "registration_enabled" => false,
        "email_login_enabled" => true
      )
    end

    it "requires authentication" do
      get "/api/v1/admin/settings"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/admin/settings" do
    it "updates authentication settings" do
      user = create(:user)
      settings_params = { registration_enabled: false, email_login_enabled: false }

      patch "/api/v1/admin/settings",
            params: { settings: settings_params },
            headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response).to include("registration_enabled" => false, "email_login_enabled" => false)
      expect(ApplicationSetting.current).to have_attributes(settings_params)
    end
  end
end

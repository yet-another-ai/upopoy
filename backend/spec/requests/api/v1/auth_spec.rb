require "rails_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  around do |example|
    OmniAuth.config.test_mode = true
    example.run
  ensure
    OmniAuth.config.mock_auth[:developer] = nil
    OmniAuth.config.test_mode = false
  end

  describe "GET /api/v1/auth/providers" do
    it "returns configured OAuth providers" do
      get "/api/v1/auth/providers"

      expect(response).to have_http_status(:ok)
      expect(json_response).to include(
        a_hash_including(
          "name" => "developer",
          "label" => "Developer",
          "authorize_path" => "/api/v1/auth/developer"
        )
      )
    end
  end

  describe "GET /api/v1/auth/settings" do
    it "returns public authentication settings" do
      ApplicationSetting.current.update!(registration_enabled: false, email_login_enabled: false)

      get "/api/v1/auth/settings"

      expect(response).to have_http_status(:ok)
      expect(json_response).to include(
        "registration_enabled" => false,
        "email_login_enabled" => false
      )
    end
  end

  describe "POST /api/v1/auth/signup" do
    it "creates a user and dispatches a JWT" do
      post "/api/v1/auth/signup",
           params: {
             user: {
               email: "founder@example.com",
               password: "password123",
               password_confirmation: "password123"
             }
           }

      expect(response).to have_http_status(:created)
      expect(response.headers["Authorization"]).to start_with("Bearer ")
      expect(json_response.dig("user", "email")).to eq("founder@example.com")
    end

    it "returns validation errors" do
      post "/api/v1/auth/signup",
           params: { user: { email: "founder@example.com", password: "short" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response["errors"]).to be_present
    end

    it "rejects signup when registration is disabled" do
      ApplicationSetting.current.update!(registration_enabled: false)

      post "/api/v1/auth/signup",
           params: {
             user: {
               email: "founder@example.com",
               password: "password123",
               password_confirmation: "password123"
             }
           }

      expect(response).to have_http_status(:forbidden)
      expect(json_response["error"]).to eq("Registration is disabled")
    end

    it "returns localized errors from the Accept-Language header" do
      ApplicationSetting.current.update!(registration_enabled: false)

      post "/api/v1/auth/signup",
           params: {
             user: {
               email: "founder@example.com",
               password: "password123",
               password_confirmation: "password123"
             }
           },
           headers: { "Accept-Language" => "zh-CN" }

      expect(response).to have_http_status(:forbidden)
      expect(json_response["error"]).to eq("注册已禁用")
    end
  end

  describe "POST /api/v1/auth/login" do
    it "signs in a user and dispatches a JWT" do
      create(:user, email: "founder@example.com", password: "password123")

      post "/api/v1/auth/login",
           params: { user: { email: "founder@example.com", password: "password123" } }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Authorization"]).to start_with("Bearer ")
      expect(json_response.dig("user", "email")).to eq("founder@example.com")
    end

    it "rejects invalid credentials" do
      create(:user, email: "founder@example.com", password: "password123")

      post "/api/v1/auth/login",
           params: { user: { email: "founder@example.com", password: "wrong-password" } }

      expect(response).to have_http_status(:unauthorized)
      expect(json_response["error"]).to eq("Invalid email or password")
    end

    it "rejects email login when email login is disabled" do
      create(:user, email: "founder@example.com", password: "password123")
      ApplicationSetting.current.update!(email_login_enabled: false)

      post "/api/v1/auth/login",
           params: { user: { email: "founder@example.com", password: "password123" } }

      expect(response).to have_http_status(:forbidden)
      expect(json_response["error"]).to eq("Email login is disabled")
    end
  end

  describe "GET /api/v1/auth/me" do
    it "returns the current user for a valid JWT" do
      user = create(:user)
      token = auth_token_for(user)

      get "/api/v1/auth/me", headers: { "Authorization" => token }

      expect(response).to have_http_status(:ok)
      expect(json_response.dig("user", "id")).to eq(user.id)
    end

    it "rejects requests without a JWT" do
      get "/api/v1/auth/me"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/auth/logout" do
    it "revokes the current JWT" do
      user = create(:user)
      token = auth_token_for(user)

      delete "/api/v1/auth/logout", headers: { "Authorization" => token }
      get "/api/v1/auth/me", headers: { "Authorization" => token }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/auth/developer/callback" do
    it "creates a user and redirects to the frontend callback with a JWT" do
      OmniAuth.config.mock_auth[:developer] = OmniAuth::AuthHash.new(
        provider: "developer",
        uid: "developer-42",
        info: { email: "developer@example.com" }
      )

      get "/api/v1/auth/developer/callback"

      expect(response).to redirect_to(%r{\Ahttp://localhost:3000/auth/callback#})

      token = callback_fragment.fetch("token")
      get "/api/v1/auth/me", headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
      expect(json_response.dig("user", "email")).to eq("developer@example.com")
    end

    it "redirects callback failures to the frontend callback" do
      OmniAuth.config.mock_auth[:developer] = :invalid_credentials

      get "/api/v1/auth/developer/callback"

      expect(response).to redirect_to(%r{\Ahttp://localhost:3000/auth/callback#})
      expect(callback_fragment.fetch("error")).to be_present
    end
  end

  def auth_token_for(user)
    post "/api/v1/auth/login", params: { user: { email: user.email, password: "password123" } }

    response.headers.fetch("Authorization")
  end

  def callback_fragment
    fragment = URI(response.location).fragment
    Rack::Utils.parse_nested_query(fragment)
  end
end

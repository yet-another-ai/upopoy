require "openapi_helper"

# rubocop:disable RSpec/NestedGroups, RSpec/VariableName
RSpec.describe "Api::V1::Auth", openapi_spec: "v1/openapi.yaml", type: :request do
  path "/api/v1/auth/settings" do
    get "Returns public authentication settings" do
      tags "Authentication"
      produces "application/json"

      response "200", "settings returned" do
        schema "$ref" => "#/components/schemas/auth_settings"

        run_test!
      end
    end
  end

  path "/api/v1/auth/providers" do
    get "Lists configured OAuth providers" do
      tags "Authentication"
      produces "application/json"

      response "200", "providers returned" do
        schema type: :array, items: { "$ref" => "#/components/schemas/auth_provider" }

        run_test!
      end
    end
  end

  path "/api/v1/auth/signup" do
    post "Creates a user account" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"
      parameter name: :request_params, in: :body, schema: { "$ref" => "#/components/schemas/signup_request" }

      response "201", "user created" do
        header "Authorization", schema: { type: :string }, description: "Bearer JWT"
        schema "$ref" => "#/components/schemas/user_response"

        let(:request_params) do
          {
            user: {
              email: "founder@example.com",
              password: "password123",
              password_confirmation: "password123"
            }
          }
        end

        run_test!
      end

      response "422", "validation failed" do
        schema "$ref" => "#/components/schemas/error"

        let(:request_params) do
          {
            user: {
              email: "founder@example.com",
              password: "short",
              password_confirmation: "short"
            }
          }
        end

        run_test!
      end
    end
  end

  path "/api/v1/auth/login" do
    post "Authenticates with email and password" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"
      parameter name: :request_params, in: :body, schema: { "$ref" => "#/components/schemas/credentials" }

      response "200", "signed in" do
        header "Authorization", schema: { type: :string }, description: "Bearer JWT"
        schema "$ref" => "#/components/schemas/user_response"

        let!(:user) { create(:user, email: "founder@example.com", password: "password123") }
        let(:request_params) { { user: { email: user.email, password: "password123" } } }

        run_test!
      end

      response "401", "invalid credentials" do
        schema "$ref" => "#/components/schemas/error"

        let!(:user) { create(:user, email: "founder@example.com", password: "password123") }
        let(:request_params) { { user: { email: user.email, password: "wrong-password" } } }

        run_test!
      end
    end
  end

  path "/api/v1/auth/me" do
    get "Returns the current user" do
      tags "Authentication"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "200", "current user returned" do
        schema "$ref" => "#/components/schemas/user_response"

        let(:user) { create(:user) }
        let(:Authorization) { auth_headers_for(user).fetch("Authorization") }

        run_test!
      end

      response "401", "authentication required" do
        schema "$ref" => "#/components/schemas/error"

        let(:Authorization) { nil }

        run_test!
      end
    end
  end

  path "/api/v1/auth/logout" do
    delete "Revokes the current JWT" do
      tags "Authentication"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "200", "signed out" do
        schema type: :object,
          properties: {
            message: { type: :string }
          },
          required: %w[message]

        let(:user) { create(:user) }
        let(:Authorization) { auth_headers_for(user).fetch("Authorization") }

        run_test!
      end
    end
  end
end
# rubocop:enable RSpec/NestedGroups, RSpec/VariableName

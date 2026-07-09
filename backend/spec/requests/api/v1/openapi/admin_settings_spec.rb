require "openapi_helper"

# rubocop:disable RSpec/NestedGroups, RSpec/RepeatedExampleGroupBody, RSpec/VariableName
RSpec.describe "Api::V1::Admin::Settings", openapi_spec: "v1/openapi.yaml", type: :request do
  let(:current_user) { create(:user, :system_admin) }
  let(:Authorization) { auth_headers_for(current_user).fetch("Authorization") }

  path "/api/v1/admin/settings" do
    get "Returns application settings" do
      tags "Admin settings"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "200", "settings returned" do
        schema "$ref" => "#/components/schemas/admin_settings"

        run_test!
      end
    end

    patch "Updates application settings" do
      tags "Admin settings"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :request_params, in: :body, schema: { "$ref" => "#/components/schemas/admin_settings_request" }

      response "200", "settings updated" do
        schema "$ref" => "#/components/schemas/admin_settings"

        let(:request_params) do
          {
            settings: {
              registration_enabled: false,
              email_login_enabled: false
            }
          }
        end

        run_test!
      end
    end

    put "Replaces application settings" do
      tags "Admin settings"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :request_params, in: :body, schema: { "$ref" => "#/components/schemas/admin_settings_request" }

      response "200", "settings updated" do
        schema "$ref" => "#/components/schemas/admin_settings"

        let(:request_params) do
          {
            settings: {
              registration_enabled: false,
              email_login_enabled: false
            }
          }
        end

        run_test!
      end
    end
  end
end
# rubocop:enable RSpec/NestedGroups, RSpec/RepeatedExampleGroupBody, RSpec/VariableName

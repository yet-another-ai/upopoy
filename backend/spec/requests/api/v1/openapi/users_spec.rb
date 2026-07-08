require "openapi_helper"

# rubocop:disable RSpec/NestedGroups, RSpec/RepeatedExampleGroupBody, RSpec/VariableName
RSpec.describe "Api::V1::Users", openapi_spec: "v1/openapi.yaml", type: :request do
  let(:current_user) { create(:user) }
  let(:Authorization) { auth_headers_for(current_user).fetch("Authorization") }

  path "/api/v1/users" do
    get "Lists users" do
      tags "Users"
      security [ bearer_auth: [] ]
      produces "application/json"
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response "200", "users returned" do
        schema "$ref" => "#/components/schemas/users_index"

        let(:page) { 1 }
        let(:per_page) { 10 }

        before do
          create(:user)
        end

        run_test!
      end
    end
  end

  path "/api/v1/users/{id}" do
    parameter name: :id, in: :path, type: :integer

    get "Returns a user profile" do
      tags "Users"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "200", "user returned" do
        schema "$ref" => "#/components/schemas/managed_user"

        let(:id) { create(:user).id }

        run_test!
      end
    end

    patch "Updates a user profile" do
      tags "Users"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :request_params, in: :body, schema: { "$ref" => "#/components/schemas/user_update_request" }

      response "200", "user updated" do
        schema "$ref" => "#/components/schemas/managed_user"

        let(:id) { create(:user).id }
        let(:request_params) do
          {
            user: {
              email: "new@example.com",
              display_name: "Grace Hopper",
              title: "Admiral",
              bio: "Compiler pioneer."
            }
          }
        end

        run_test!
      end
    end

    put "Replaces a user profile" do
      tags "Users"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :request_params, in: :body, schema: { "$ref" => "#/components/schemas/user_update_request" }

      response "200", "user updated" do
        schema "$ref" => "#/components/schemas/managed_user"

        let(:id) { create(:user).id }
        let(:request_params) do
          {
            user: {
              email: "new@example.com",
              display_name: "Grace Hopper",
              title: "Admiral",
              bio: "Compiler pioneer."
            }
          }
        end

        run_test!
      end
    end
  end
end
# rubocop:enable RSpec/NestedGroups, RSpec/RepeatedExampleGroupBody, RSpec/VariableName

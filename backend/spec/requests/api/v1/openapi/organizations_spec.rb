require "openapi_helper"

# rubocop:disable RSpec/NestedGroups, RSpec/RepeatedExampleGroupBody, RSpec/VariableName
RSpec.describe "Api::V1::Organizations", openapi_spec: "v1/openapi.yaml", type: :request do
  let(:current_user) { create(:user) }
  let(:Authorization) { auth_headers_for(current_user).fetch("Authorization") }

  path "/api/v1/organizations" do
    get "Lists accessible organizations" do
      tags "Organizations"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "200", "organizations returned" do
        schema type: :array, items: { "$ref" => "#/components/schemas/organization" }

        before do
          organization = create(:organization)
          create(:organization_membership, user: current_user, organization:)
        end

        run_test!
      end
    end

    post "Creates a organization" do
      tags "Organizations"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :request_params, in: :body, schema: { "$ref" => "#/components/schemas/organization_request" }

      response "201", "organization created" do
        schema "$ref" => "#/components/schemas/organization"

        let(:member) { create(:user) }
        let(:request_params) do
          {
            organization: {
              name: "Product",
              description: "Product planning",
              user_ids: [ member.id ]
            }
          }
        end

        run_test!
      end
    end
  end

  path "/api/v1/organizations/{id}" do
    parameter name: :id, in: :path, type: :integer

    get "Returns a organization" do
      tags "Organizations"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "200", "organization returned" do
        schema "$ref" => "#/components/schemas/organization"

        let(:organization) { create(:organization) }
        let(:id) { organization.id }

        before do
          create(:organization_membership, user: current_user, organization:)
        end

        run_test!
      end
    end

    patch "Updates a organization" do
      tags "Organizations"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :request_params, in: :body, schema: { "$ref" => "#/components/schemas/organization_request" }

      response "200", "organization updated" do
        schema "$ref" => "#/components/schemas/organization"

        let(:organization) { create(:organization) }
        let(:id) { organization.id }
        let(:request_params) { { organization: { name: "Renamed", user_ids: [ current_user.id ] } } }

        before do
          create(:organization_membership, :admin, user: current_user, organization:)
        end

        run_test!
      end
    end

    put "Replaces a organization" do
      tags "Organizations"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :request_params, in: :body, schema: { "$ref" => "#/components/schemas/organization_request" }

      response "200", "organization updated" do
        schema "$ref" => "#/components/schemas/organization"

        let(:organization) { create(:organization) }
        let(:id) { organization.id }
        let(:request_params) { { organization: { name: "Renamed", user_ids: [ current_user.id ] } } }

        before do
          create(:organization_membership, :admin, user: current_user, organization:)
        end

        run_test!
      end
    end

    delete "Deletes a organization" do
      tags "Organizations"
      security [ bearer_auth: [] ]

      response "204", "organization deleted" do
        let(:organization) { create(:organization) }
        let(:id) { organization.id }

        before do
          create(:organization_membership, :admin, user: current_user, organization:)
        end

        run_test!
      end
    end
  end
end
# rubocop:enable RSpec/NestedGroups, RSpec/RepeatedExampleGroupBody, RSpec/VariableName

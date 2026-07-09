require "openapi_helper"

# rubocop:disable RSpec/NestedGroups, RSpec/VariableName
RSpec.describe "Api::V1::Search", openapi_spec: "v1/openapi.yaml", type: :request do
  let(:current_user) { create(:user) }
  let(:Authorization) { auth_headers_for(current_user).fetch("Authorization") }

  path "/api/v1/search" do
    get "Searches accessible resources" do
      tags "Search"
      security [ bearer_auth: [] ]
      produces "application/json"
      parameter name: :q, in: :query, type: :string, required: true
      parameter name: :type, in: :query, type: :string, required: false, enum: %w[organization project task user]

      response "200", "results returned" do
        schema "$ref" => "#/components/schemas/search_response"

        let(:q) { "Apollo" }
        let(:type) { nil }

        before do
          create(:project, user: current_user, name: "Apollo")
        end

        run_test!
      end
    end
  end
end
# rubocop:enable RSpec/NestedGroups, RSpec/VariableName

require "openapi_helper"

# rubocop:disable RSpec/NestedGroups, RSpec/RepeatedExampleGroupBody, RSpec/VariableName
RSpec.describe "Api::V1::Iterations", openapi_spec: "v1/openapi.yaml", type: :request do
  let(:current_user) { create(:user) }
  let(:Authorization) { auth_headers_for(current_user).fetch("Authorization") }

  path "/api/v1/projects/{project_id}/iterations" do
    parameter name: :project_id, in: :path, type: :integer

    get "Lists project iterations" do
      tags "Iterations"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "200", "iterations returned" do
        schema type: :array, items: { "$ref" => "#/components/schemas/iteration" }

        let(:project) { create(:project, user: current_user) }
        let(:project_id) { project.id }

        before do
          create(:iteration, project:, name: "Sprint 1")
        end

        run_test!
      end
    end

    post "Creates an iteration" do
      tags "Iterations"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :request_params, in: :body, schema: { "$ref" => "#/components/schemas/iteration_request" }

      response "201", "iteration created" do
        schema "$ref" => "#/components/schemas/iteration"

        let(:project) { create(:project, user: current_user) }
        let(:project_id) { project.id }
        let(:request_params) do
          {
            iteration: {
              name: "Sprint 1",
              starts_at: "2026-07-25T10:00:00Z",
              deadline: "2026-08-01T10:00:00Z"
            }
          }
        end

        run_test!
      end
    end
  end

  path "/api/v1/iterations/{id}" do
    parameter name: :id, in: :path, type: :integer

    get "Returns an iteration" do
      tags "Iterations"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "200", "iteration returned" do
        schema "$ref" => "#/components/schemas/iteration"

        let(:iteration) { create(:iteration, project: create(:project, user: current_user)) }
        let(:id) { iteration.id }

        run_test!
      end
    end

    patch "Updates an iteration" do
      tags "Iterations"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :request_params, in: :body, schema: { "$ref" => "#/components/schemas/iteration_request" }

      response "200", "iteration updated" do
        schema "$ref" => "#/components/schemas/iteration"

        let(:iteration) { create(:iteration, project: create(:project, user: current_user)) }
        let(:id) { iteration.id }
        let(:request_params) do
          {
            iteration: {
              name: "Renamed",
              starts_at: "2026-08-01T10:00:00Z",
              deadline: "2026-08-08T10:00:00Z"
            }
          }
        end

        run_test!
      end
    end

    put "Replaces an iteration" do
      tags "Iterations"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :request_params, in: :body, schema: { "$ref" => "#/components/schemas/iteration_request" }

      response "200", "iteration updated" do
        schema "$ref" => "#/components/schemas/iteration"

        let(:iteration) { create(:iteration, project: create(:project, user: current_user)) }
        let(:id) { iteration.id }
        let(:request_params) do
          {
            iteration: {
              name: "Renamed",
              starts_at: "2026-08-01T10:00:00Z",
              deadline: "2026-08-08T10:00:00Z"
            }
          }
        end

        run_test!
      end
    end

    delete "Deletes an iteration" do
      tags "Iterations"
      security [ bearer_auth: [] ]

      response "204", "iteration deleted" do
        let(:iteration) { create(:iteration, project: create(:project, user: current_user)) }
        let(:id) { iteration.id }

        run_test!
      end
    end
  end
end
# rubocop:enable RSpec/NestedGroups, RSpec/RepeatedExampleGroupBody, RSpec/VariableName

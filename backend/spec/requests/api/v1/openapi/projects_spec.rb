require "openapi_helper"

# rubocop:disable RSpec/NestedGroups, RSpec/RepeatedExampleGroupBody, RSpec/VariableName
RSpec.describe "Api::V1::Projects", openapi_spec: "v1/openapi.yaml", type: :request do
  let(:current_user) { create(:user) }
  let(:Authorization) { auth_headers_for(current_user).fetch("Authorization") }

  path "/api/v1/projects" do
    get "Lists accessible projects" do
      tags "Projects"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "200", "projects returned" do
        schema type: :array, items: { "$ref" => "#/components/schemas/project" }

        before do
          create(:project, user: current_user, name: "Apollo")
        end

        run_test!
      end
    end

    post "Creates a project" do
      tags "Projects"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :request_params, in: :body, schema: { "$ref" => "#/components/schemas/project_request" }

      response "201", "project created" do
        schema "$ref" => "#/components/schemas/project"

        let(:group) { create(:group) }
        let(:request_params) do
          {
            project: {
              name: "AI Ops",
              description: "Agent-managed work.",
              group_id: group.id
            }
          }
        end

        before do
          create(:group_membership, user: current_user, group:)
        end

        run_test!
      end
    end
  end

  path "/api/v1/projects/{id}" do
    parameter name: :id, in: :path, type: :integer

    get "Returns a project" do
      tags "Projects"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "200", "project returned" do
        schema "$ref" => "#/components/schemas/project"

        let(:project) { create(:project, user: current_user) }
        let(:id) { project.id }

        run_test!
      end
    end

    patch "Updates a project" do
      tags "Projects"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :request_params, in: :body, schema: { "$ref" => "#/components/schemas/project_request" }

      response "200", "project updated" do
        schema "$ref" => "#/components/schemas/project"

        let(:project) { create(:project, user: current_user) }
        let(:id) { project.id }
        let(:request_params) { { project: { name: "Renamed" } } }

        run_test!
      end
    end

    put "Replaces a project" do
      tags "Projects"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :request_params, in: :body, schema: { "$ref" => "#/components/schemas/project_request" }

      response "200", "project updated" do
        schema "$ref" => "#/components/schemas/project"

        let(:project) { create(:project, user: current_user) }
        let(:id) { project.id }
        let(:request_params) { { project: { name: "Renamed" } } }

        run_test!
      end
    end

    delete "Deletes a project" do
      tags "Projects"
      security [ bearer_auth: [] ]

      response "204", "project deleted" do
        let(:project) { create(:project, user: current_user) }
        let(:id) { project.id }

        run_test!
      end
    end
  end

  path "/api/v1/projects/{id}/board" do
    parameter name: :id, in: :path, type: :integer

    get "Returns a project board" do
      tags "Projects"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "200", "board returned" do
        schema "$ref" => "#/components/schemas/board"

        let(:project) { create(:project, user: current_user) }
        let(:id) { project.id }

        before do
          iteration = create(:iteration, project:, name: "Sprint 1")
          create(:task, project:, iteration:, status: "todo", title: "Plan")
        end

        run_test!
      end
    end
  end
end
# rubocop:enable RSpec/NestedGroups, RSpec/RepeatedExampleGroupBody, RSpec/VariableName

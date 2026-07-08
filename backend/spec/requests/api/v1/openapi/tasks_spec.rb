require "openapi_helper"

# rubocop:disable RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups, RSpec/RepeatedExampleGroupBody, RSpec/VariableName
RSpec.describe "Api::V1::Tasks", openapi_spec: "v1/openapi.yaml", type: :request do
  let(:current_user) { create(:user) }
  let(:Authorization) { auth_headers_for(current_user).fetch("Authorization") }

  path "/api/v1/projects/{project_id}/tasks" do
    parameter name: :project_id, in: :path, type: :integer

    get "Lists project tasks" do
      tags "Tasks"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "200", "tasks returned" do
        schema type: :array, items: { "$ref" => "#/components/schemas/task" }

        let(:project) { create(:project, user: current_user) }
        let(:project_id) { project.id }

        before do
          create(:task, project:, title: "Draft MCP API")
        end

        run_test!
      end
    end

    post "Creates a task" do
      tags "Tasks"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :request_params, in: :body, schema: { "$ref" => "#/components/schemas/task_request" }

      response "201", "task created" do
        schema "$ref" => "#/components/schemas/task"

        let(:project) { create(:project, user: current_user) }
        let(:project_id) { project.id }
        let(:developer) { create(:user) }
        let(:reviewer) { create(:user) }
        let(:request_params) do
          {
            task: {
              title: "Draft MCP API",
              description: "Keep resources clear.",
              status: "in_progress",
              priority: "high",
              developer_ids: [ developer.id ],
              reviewer_ids: [ reviewer.id ]
            }
          }
        end

        run_test!
      end
    end
  end

  path "/api/v1/tasks/{id}" do
    parameter name: :id, in: :path, type: :integer

    get "Returns a task" do
      tags "Tasks"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "200", "task returned" do
        schema "$ref" => "#/components/schemas/task"

        let(:task) { create(:task, project: create(:project, user: current_user)) }
        let(:id) { task.id }

        run_test!
      end
    end

    patch "Updates a task" do
      tags "Tasks"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :request_params, in: :body, schema: { "$ref" => "#/components/schemas/task_request" }

      response "200", "task updated" do
        schema "$ref" => "#/components/schemas/task"

        let(:task) { create(:task, project: create(:project, user: current_user)) }
        let(:id) { task.id }
        let(:request_params) do
          {
            task: {
              status: "done",
              priority: "high",
              position: 4,
              deadline: "2026-07-31T15:45:00Z",
              estimated_minutes: 240
            }
          }
        end

        run_test!
      end
    end

    put "Replaces a task" do
      tags "Tasks"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :request_params, in: :body, schema: { "$ref" => "#/components/schemas/task_request" }

      response "200", "task updated" do
        schema "$ref" => "#/components/schemas/task"

        let(:task) { create(:task, project: create(:project, user: current_user)) }
        let(:id) { task.id }
        let(:request_params) do
          {
            task: {
              status: "done",
              priority: "high",
              position: 4,
              deadline: "2026-07-31T15:45:00Z",
              estimated_minutes: 240
            }
          }
        end

        run_test!
      end
    end

    delete "Deletes a task" do
      tags "Tasks"
      security [ bearer_auth: [] ]

      response "204", "task deleted" do
        let(:task) { create(:task, project: create(:project, user: current_user)) }
        let(:id) { task.id }

        run_test!
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups, RSpec/RepeatedExampleGroupBody, RSpec/VariableName

require "openapi_helper"

# rubocop:disable RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups, RSpec/RepeatedExampleGroupBody, RSpec/VariableName
RSpec.describe "Api::V1::DriveItems", openapi_spec: "v1/openapi.yaml", type: :request do
  let(:current_user) { create(:user) }
  let(:Authorization) { auth_headers_for(current_user).fetch("Authorization") }

  def uploaded_file(filename, content, content_type = "text/markdown")
    file = Tempfile.new([ File.basename(filename, ".*"), File.extname(filename) ])
    file.write(content)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, content_type, original_filename: filename)
  end

  path "/api/v1/projects/{project_id}/drive_items" do
    parameter name: :project_id, in: :path, type: :integer
    parameter name: :parent_id, in: :query, type: :integer, required: false, nullable: true

    get "Lists project drive items" do
      tags "Drive"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "200", "drive items returned" do
        schema type: :array, items: { "$ref" => "#/components/schemas/drive_item" }

        let(:project) { create(:project, user: current_user) }
        let(:project_id) { project.id }
        let(:parent_id) { nil }

        before do
          create(:drive_item, project:, name: "Specs")
        end

        run_test!
      end
    end

    post "Creates a drive item" do
      tags "Drive"
      security [ bearer_auth: [] ]
      consumes "application/json", "multipart/form-data"
      produces "application/json"
      parameter name: :request_params, in: :body, schema: {
        oneOf: [
          { "$ref" => "#/components/schemas/drive_item_request" },
          { "$ref" => "#/components/schemas/drive_item_upload_request" }
        ]
      }

      response "201", "drive item created" do
        schema "$ref" => "#/components/schemas/drive_item"

        let(:project) { create(:project, user: current_user) }
        let(:project_id) { project.id }
        let(:request_params) do
          {
            drive_item: {
              kind: "file",
              name: "Notes.md",
              content: "# Notes",
              base_version_number: nil
            }
          }
        end

        run_test!
      end
    end
  end

  path "/api/v1/drive_items/{id}" do
    parameter name: :id, in: :path, type: :integer

    get "Returns a drive item" do
      tags "Drive"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "200", "drive item returned" do
        schema "$ref" => "#/components/schemas/drive_item"

        let(:drive_item) { create(:drive_item, project: create(:project, user: current_user)) }
        let(:id) { drive_item.id }

        run_test!
      end
    end

    patch "Updates a drive item" do
      tags "Drive"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :request_params, in: :body, schema: { "$ref" => "#/components/schemas/drive_item_request" }

      response "200", "drive item updated" do
        schema "$ref" => "#/components/schemas/drive_item"

        let(:drive_item) { create(:drive_item, project: create(:project, user: current_user)) }
        let(:id) { drive_item.id }
        let(:request_params) { { drive_item: { name: "Renamed" } } }

        run_test!
      end
    end

    delete "Deletes a drive item" do
      tags "Drive"
      security [ bearer_auth: [] ]

      response "204", "drive item deleted" do
        let(:drive_item) { create(:drive_item, project: create(:project, user: current_user)) }
        let(:id) { drive_item.id }

        run_test!
      end
    end
  end

  path "/api/v1/drive_items/{id}/file" do
    parameter name: :id, in: :path, type: :integer

    patch "Uploads a new file version" do
      tags "Drive"
      security [ bearer_auth: [] ]
      consumes "multipart/form-data"
      produces "application/json"
      parameter name: :"drive_item[file]", in: :formData, type: :file
      parameter name: :"drive_item[name]", in: :formData, type: :string, required: false
      parameter name: :"drive_item[base_version_number]", in: :formData, type: :integer, required: true, nullable: true

      response "200", "file version uploaded" do
        schema "$ref" => "#/components/schemas/drive_item"

        let(:drive_item) { create(:drive_item, :file, project: create(:project, user: current_user)) }
        let(:id) { drive_item.id }
        let(:"drive_item[file]") { uploaded_file("Guide.txt", "Updated", "text/plain") }
        let(:"drive_item[name]") { "Guide.txt" }
        let(:"drive_item[base_version_number]") { nil }

        run_test!
      end
    end
  end

  path "/api/v1/drive_items/{id}/content" do
    parameter name: :id, in: :path, type: :integer

    get "Returns markdown content" do
      tags "Drive"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "200", "markdown content returned" do
        schema "$ref" => "#/components/schemas/drive_item_content"

        let(:drive_item) { create(:drive_item, :markdown, project: create(:project, user: current_user)) }
        let(:id) { drive_item.id }

        run_test!
      end
    end

    patch "Updates markdown content" do
      tags "Drive"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :request_params, in: :body, schema: { "$ref" => "#/components/schemas/drive_item_request" }

      response "200", "markdown content updated" do
        schema "$ref" => "#/components/schemas/drive_item_content"

        let(:drive_item) { create(:drive_item, :markdown, project: create(:project, user: current_user)) }
        let(:id) { drive_item.id }
        let(:request_params) { { drive_item: { content: "# Updated", base_version_number: nil } } }

        run_test!
      end
    end
  end

  path "/api/v1/drive_items/{id}/versions" do
    parameter name: :id, in: :path, type: :integer

    get "Lists drive item versions" do
      tags "Drive"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "200", "drive item versions returned" do
        schema type: :array, items: { "$ref" => "#/components/schemas/drive_item_version" }

        let(:drive_item) { create(:drive_item, :markdown, project: create(:project, user: current_user)) }
        let(:id) { drive_item.id }

        before do
          drive_item.record_version!
        end

        run_test!
      end
    end
  end

  path "/api/v1/drive_items/{id}/download" do
    parameter name: :id, in: :path, type: :integer

    get "Downloads a file" do
      tags "Drive"
      security [ bearer_auth: [] ]

      response "302", "redirected to blob" do
        let(:drive_item) { create(:drive_item, :file, project: create(:project, user: current_user)) }
        let(:id) { drive_item.id }

        run_test!
      end
    end
  end

  path "/api/v1/drive_item_versions/{id}/content" do
    parameter name: :id, in: :path, type: :integer

    get "Returns version markdown content" do
      tags "Drive"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "200", "version markdown content returned" do
        schema "$ref" => "#/components/schemas/drive_item_content"

        let(:drive_item) { create(:drive_item, :markdown, project: create(:project, user: current_user)) }
        let(:version) { drive_item.record_version! }
        let(:id) { version.id }

        run_test!
      end
    end
  end

  path "/api/v1/drive_item_versions/{id}/download" do
    parameter name: :id, in: :path, type: :integer

    get "Downloads a version file" do
      tags "Drive"
      security [ bearer_auth: [] ]

      response "302", "redirected to version blob" do
        let(:drive_item) { create(:drive_item, :file, project: create(:project, user: current_user)) }
        let(:version) { drive_item.record_version! }
        let(:id) { version.id }

        run_test!
      end
    end
  end

  path "/api/v1/drive_item_versions/{id}/restore" do
    parameter name: :id, in: :path, type: :integer

    post "Restores a drive item version" do
      tags "Drive"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "200", "version restored" do
        schema "$ref" => "#/components/schemas/drive_item"

        let(:drive_item) { create(:drive_item, :markdown, project: create(:project, user: current_user)) }
        let(:version) { drive_item.record_version! }
        let(:id) { version.id }

        run_test!
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups, RSpec/RepeatedExampleGroupBody, RSpec/VariableName

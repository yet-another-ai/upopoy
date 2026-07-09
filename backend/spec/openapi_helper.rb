require "rails_helper"
require "rswag/specs"

RSpec.configure do |config|
  config.openapi_root = ENV["OPENAPI_ROOT"].to_s.empty? ? Rails.root.join("openapi").to_s : ENV["OPENAPI_ROOT"]
  config.openapi_format = :yaml
  config.rswag_dry_run = false

  config.openapi_specs = {
    "v1/openapi.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "Upopoy API",
        version: "v1",
        description: "HTTP JSON API for Upopoy."
      },
      servers: [
        {
          url: "http://localhost:3001",
          description: "Local development"
        }
      ],
      components: {
        securitySchemes: {
          bearer_auth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: "JWT"
          }
        },
        schemas: {
          auth_settings: {
            type: :object,
            properties: {
              registration_enabled: { type: :boolean },
              email_login_enabled: { type: :boolean }
            },
            required: %w[registration_enabled email_login_enabled]
          },
          auth_provider: {
            type: :object,
            properties: {
              name: { type: :string },
              label: { type: :string },
              authorize_path: { type: :string }
            },
            required: %w[name label authorize_path]
          },
          user: {
            type: :object,
            properties: {
              id: { type: :integer },
              email: { type: :string, format: :email },
              display_name: { type: :string, nullable: true },
              title: { type: :string, nullable: true },
              bio: { type: :string, nullable: true },
              system_admin: { type: :boolean },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" }
            },
            required: %w[id email display_name title bio system_admin created_at updated_at]
          },
          user_response: {
            type: :object,
            properties: {
              user: { "$ref" => "#/components/schemas/user" }
            },
            required: %w[user]
          },
          credentials: {
            type: :object,
            properties: {
              user: {
                type: :object,
                properties: {
                  email: { type: :string, format: :email },
                  password: { type: :string, format: :password }
                },
                required: %w[email password]
              }
            },
            required: %w[user]
          },
          signup_request: {
            type: :object,
            properties: {
              user: {
                type: :object,
                properties: {
                  email: { type: :string, format: :email },
                  password: { type: :string, format: :password },
                  password_confirmation: { type: :string, format: :password }
                },
                required: %w[email password password_confirmation]
              }
            },
            required: %w[user]
          },
          error: {
            type: :object,
            properties: {
              error: { type: :string },
              errors: { type: :object }
            }
          },
          admin_settings: {
            type: :object,
            properties: {
              registration_enabled: { type: :boolean },
              email_login_enabled: { type: :boolean },
              updated_at: { type: :string, format: :"date-time" }
            },
            required: %w[registration_enabled email_login_enabled updated_at]
          },
          admin_settings_request: {
            type: :object,
            properties: {
              settings: {
                type: :object,
                properties: {
                  registration_enabled: { type: :boolean },
                  email_login_enabled: { type: :boolean }
                }
              }
            },
            required: %w[settings]
          },
          managed_user: {
            type: :object,
            properties: {
              id: { type: :integer },
              email: { type: :string, format: :email },
              display_name: { type: :string, nullable: true },
              title: { type: :string, nullable: true },
              bio: { type: :string, nullable: true },
              system_admin: { type: :boolean },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" },
              group_ids: { type: :array, items: { type: :integer } },
              groups_count: { type: :integer }
            },
            required: %w[id email display_name title bio system_admin created_at updated_at group_ids groups_count]
          },
          users_index: {
            type: :object,
            properties: {
              users: {
                type: :array,
                items: { "$ref" => "#/components/schemas/managed_user" }
              },
              meta: { "$ref" => "#/components/schemas/pagination_meta" }
            },
            required: %w[users meta]
          },
          user_update_request: {
            type: :object,
            properties: {
              user: {
                type: :object,
                properties: {
                  email: { type: :string, format: :email },
                  display_name: { type: :string },
                  title: { type: :string },
                  bio: { type: :string },
                  system_admin: { type: :boolean }
                }
              }
            },
            required: %w[user]
          },
          pagination_meta: {
            type: :object,
            properties: {
              current_page: { type: :integer },
              total_pages: { type: :integer },
              total_count: { type: :integer },
              per_page: { type: :integer }
            },
            required: %w[current_page total_pages total_count per_page]
          },
          group: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              description: { type: :string, nullable: true },
              parent_group_id: { type: :integer, nullable: true },
              parent_group_name: { type: :string, nullable: true },
              user_ids: { type: :array, items: { type: :integer } },
              users_count: { type: :integer },
              admin_user_ids: { type: :array, items: { type: :integer } },
              admins_count: { type: :integer },
              can_admin: { type: :boolean },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" }
            },
            required: %w[id name description parent_group_id parent_group_name user_ids users_count admin_user_ids admins_count can_admin created_at updated_at]
          },
          group_request: {
            type: :object,
            properties: {
              group: {
                type: :object,
                properties: {
                  name: { type: :string },
                  description: { type: :string },
                  parent_group_id: { type: :integer, nullable: true },
                  user_ids: { type: :array, items: { type: :integer } },
                  admin_user_ids: { type: :array, items: { type: :integer } }
                }
              }
            },
            required: %w[group]
          },
          chat_channel: {
            type: :object,
            properties: {
              id: { type: :integer },
              group_id: { type: :integer },
              name: { type: :string },
              description: { type: :string, nullable: true },
              conversation_id: { type: :integer },
              can_manage: { type: :boolean },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" }
            },
            required: %w[id group_id name description conversation_id can_manage created_at updated_at]
          },
          chat_channel_request: {
            type: :object,
            properties: {
              chat_channel: {
                type: :object,
                properties: {
                  name: { type: :string },
                  description: { type: :string }
                },
                required: %w[name]
              }
            },
            required: %w[chat_channel]
          },
          chat_message: {
            type: :object,
            properties: {
              id: { type: :integer },
              chat_conversation_id: { type: :integer },
              conversation_id: { type: :integer },
              author: { "$ref" => "#/components/schemas/user" },
              body: { type: :string },
              thread_conversation_id: { type: :integer, nullable: true },
              thread_reply_count: { type: :integer },
              thread_last_message_at: { type: :string, format: :"date-time", nullable: true },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" }
            },
            required: %w[id chat_conversation_id conversation_id author body thread_conversation_id thread_reply_count thread_last_message_at created_at updated_at]
          },
          chat_message_request: {
            type: :object,
            properties: {
              message: {
                type: :object,
                properties: {
                  body: { type: :string }
                },
                required: %w[body]
              }
            },
            required: %w[message]
          },
          chat_conversation: {
            type: :object,
            properties: {
              id: { type: :integer },
              kind: { type: :string, enum: %w[direct channel thread] },
              title: { type: :string },
              group_id: { type: :integer, nullable: true },
              group_name: { type: :string, nullable: true },
              channel_id: { type: :integer, nullable: true },
              channel_name: { type: :string, nullable: true },
              participants: { type: :array, items: { "$ref" => "#/components/schemas/user" } },
              other_participant: { "$ref" => "#/components/schemas/user", nullable: true },
              parent_message: { "$ref" => "#/components/schemas/chat_message", nullable: true },
              last_message_at: { type: :string, format: :"date-time", nullable: true },
              can_manage: { type: :boolean },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" }
            },
            required: %w[id kind title group_id group_name channel_id channel_name participants other_participant parent_message last_message_at can_manage created_at updated_at]
          },
          direct_conversation_request: {
            type: :object,
            properties: {
              user_id: { type: :integer }
            },
            required: %w[user_id]
          },
          project: {
            type: :object,
            properties: {
              id: { type: :integer },
              group_id: { type: :integer, nullable: true },
              name: { type: :string },
              description: { type: :string, nullable: true },
              group_name: { type: :string, nullable: true },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" }
            },
            required: %w[id group_id name description group_name created_at updated_at]
          },
          project_request: {
            type: :object,
            properties: {
              project: {
                type: :object,
                properties: {
                  name: { type: :string },
                  description: { type: :string },
                  group_id: { type: :integer, nullable: true }
                }
              }
            },
            required: %w[project]
          },
          drive_item: {
            type: :object,
            properties: {
              id: { type: :integer },
              project_id: { type: :integer },
              parent_id: { type: :integer, nullable: true },
              kind: { type: :string, enum: %w[folder file] },
              name: { type: :string },
              text_content_cache: { type: :string },
              markdown: { type: :boolean },
              content_type: { type: :string, nullable: true },
              byte_size: { type: :integer, nullable: true },
              download_path: { type: :string, nullable: true },
              deleted_at: { type: :string, format: :"date-time", nullable: true },
              versions_count: { type: :integer },
              latest_version_number: { type: :integer, nullable: true },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" }
            },
            required: %w[id project_id parent_id kind name text_content_cache markdown content_type byte_size download_path deleted_at versions_count latest_version_number created_at updated_at]
          },
          drive_item_version: {
            type: :object,
            properties: {
              id: { type: :integer },
              drive_item_id: { type: :integer },
              version_number: { type: :integer },
              name: { type: :string },
              content_type: { type: :string, nullable: true },
              byte_size: { type: :integer, nullable: true },
              text_content_cache: { type: :string },
              markdown: { type: :boolean },
              download_path: { type: :string },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" }
            },
            required: %w[id drive_item_id version_number name content_type byte_size text_content_cache markdown download_path created_at updated_at]
          },
          drive_item_request: {
            type: :object,
            properties: {
              drive_item: {
                type: :object,
                properties: {
                  kind: { type: :string, enum: %w[folder file] },
                  name: { type: :string },
                  parent_id: { type: :integer, nullable: true },
                  content: { type: :string },
                  base_version_number: { type: :integer, nullable: true }
                }
              }
            },
            required: %w[drive_item]
          },
          drive_item_upload_request: {
            type: :object,
            properties: {
              drive_item: {
                type: :object,
                properties: {
                  kind: { type: :string, enum: %w[file] },
                  name: { type: :string },
                  parent_id: { type: :integer, nullable: true },
                  file: { type: :string, format: :binary },
                  base_version_number: { type: :integer, nullable: true }
                }
              }
            },
            required: %w[drive_item]
          },
          drive_item_content: {
            type: :object,
            properties: {
              content: { type: :string }
            },
            required: %w[content]
          },
          iteration: {
            type: :object,
            properties: {
              id: { type: :integer },
              project_id: { type: :integer },
              name: { type: :string },
              starts_at: { type: :string, format: :"date-time", nullable: true },
              deadline: { type: :string, format: :"date-time", nullable: true },
              inbox: { type: :boolean },
              task_count: { type: :integer },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" }
            },
            required: %w[id project_id name starts_at deadline inbox task_count created_at updated_at]
          },
          iteration_request: {
            type: :object,
            properties: {
              iteration: {
                type: :object,
                properties: {
                  name: { type: :string },
                  starts_at: { type: :string, format: :"date-time" },
                  deadline: { type: :string, format: :"date-time" }
                }
              }
            },
            required: %w[iteration]
          },
          task: {
            type: :object,
            properties: {
              id: { type: :integer },
              project_id: { type: :integer },
              iteration_id: { type: :integer, nullable: true },
              status: { type: :string, enum: %w[todo in_progress under_review done] },
              priority: { type: :string, enum: %w[low medium high] },
              title: { type: :string },
              description: { type: :string, nullable: true },
              estimated_minutes: { type: :integer, nullable: true },
              position: { type: :integer },
              iteration_name: { type: :string, nullable: true },
              iteration_starts_at: { type: :string, format: :"date-time", nullable: true },
              iteration_deadline: { type: :string, format: :"date-time", nullable: true },
              iteration_inbox: { type: :boolean, nullable: true },
              deadline: { type: :string, format: :"date-time", nullable: true },
              developer_ids: { type: :array, items: { type: :integer } },
              developers: { type: :array, items: { "$ref" => "#/components/schemas/user" } },
              reviewer_ids: { type: :array, items: { type: :integer } },
              reviewers: { type: :array, items: { "$ref" => "#/components/schemas/user" } },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" }
            },
            required: %w[id project_id iteration_id status priority title description estimated_minutes position iteration_name iteration_starts_at iteration_deadline iteration_inbox deadline developer_ids developers reviewer_ids reviewers created_at updated_at]
          },
          task_request: {
            type: :object,
            properties: {
              task: {
                type: :object,
                properties: {
                  status: { type: :string, enum: %w[todo in_progress under_review done] },
                  priority: { type: :string, enum: %w[low medium high] },
                  title: { type: :string },
                  description: { type: :string },
                  deadline: { type: :string, format: :"date-time", nullable: true },
                  estimated_minutes: { type: :integer, nullable: true },
                  iteration_id: { type: :integer, nullable: true },
                  position: { type: :integer },
                  developer_ids: { type: :array, items: { type: :integer } },
                  reviewer_ids: { type: :array, items: { type: :integer } }
                }
              }
            },
            required: %w[task]
          },
          board: {
            type: :object,
            properties: {
              project: { "$ref" => "#/components/schemas/project" },
              iterations: { type: :array, items: { "$ref" => "#/components/schemas/iteration" } },
              inbox_iteration: { "$ref" => "#/components/schemas/iteration" },
              statuses: {
                type: :array,
                items: { "$ref" => "#/components/schemas/board_status" }
              }
            },
            required: %w[project iterations inbox_iteration statuses]
          },
          board_status: {
            type: :object,
            properties: {
              id: { type: :string },
              name: { type: :string },
              slug: { type: :string },
              position: { type: :integer },
              tasks: { type: :array, items: { "$ref" => "#/components/schemas/task" } }
            },
            required: %w[id name slug position tasks]
          },
          search_result: {
            type: :object,
            properties: {
              slug: { type: :string },
              type: { type: :string },
              id: { type: :integer },
              title: { type: :string },
              snippet: { type: :string },
              api_path: { type: :string },
              metadata: { type: :object },
              updated_at: { type: :string, format: :"date-time", nullable: true }
            },
            required: %w[slug type id title snippet api_path metadata updated_at]
          },
          search_response: {
            type: :object,
            properties: {
              results: { type: :array, items: { "$ref" => "#/components/schemas/search_result" } }
            },
            required: %w[results]
          }
        }
      }
    }
  }

  normalize_example = lambda do |value|
    case value
    when Array
      value.map { |item| normalize_example.call(item) }
    when Hash
      value.each_with_object({}) do |(key, item), normalized|
        case key.to_s
        when "id"
          normalized[key] = 1
        when "created_at", "updated_at"
          normalized[key] = "2026-01-01T00:00:00.000Z"
        else
          normalized[key] = normalize_example.call(item)
        end
      end
    else
      value
    end
  end

  config.after(:each, :operation) do |example|
    next if response.nil?
    next if response.body.blank?

    mime = response.media_type || "application/json"
    next unless mime == "application/json"

    content = example.metadata[:response][:content] || {}
    parsed_body = JSON.parse(response.body)
    example.metadata[:response][:content] = content.deep_merge(
      mime => {
        examples: {
          response: {
            value: normalize_example.call(parsed_body)
          }
        }
      }
    )
  rescue JSON::ParserError
    nil
  end
end

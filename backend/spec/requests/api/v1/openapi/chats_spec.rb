require "openapi_helper"

# rubocop:disable RSpec/NestedGroups, RSpec/RepeatedExampleGroupBody, RSpec/VariableName, RSpec/MultipleMemoizedHelpers
RSpec.describe "Api::V1::Chats", openapi_spec: "v1/openapi.yaml", type: :request do
  let(:current_user) { create(:user) }
  let(:Authorization) { auth_headers_for(current_user).fetch("Authorization") }

  path "/api/v1/chats/conversations" do
    get "Lists accessible chat conversations" do
      tags "Chats"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "200", "conversations returned" do
        schema type: :array, items: { "$ref" => "#/components/schemas/chat_conversation" }

        before do
          other_user = create(:user)
          Chats::DirectConversationFinder.call(current_user:, other_user:)
        end

        run_test!
      end
    end
  end

  path "/api/v1/chats/conversations/{id}" do
    parameter name: :id, in: :path, type: :integer

    get "Returns a chat conversation" do
      tags "Chats"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "200", "conversation returned" do
        schema "$ref" => "#/components/schemas/chat_conversation"

        let(:other_user) { create(:user) }
        let(:conversation) { Chats::DirectConversationFinder.call(current_user:, other_user:) }
        let(:id) { conversation.id }

        run_test!
      end
    end
  end

  path "/api/v1/chats/direct_conversations" do
    post "Creates or returns a direct conversation" do
      tags "Chats"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :request_params, in: :body, schema: { "$ref" => "#/components/schemas/direct_conversation_request" }

      response "201", "direct conversation returned" do
        schema "$ref" => "#/components/schemas/chat_conversation"

        let(:other_user) { create(:user) }
        let(:request_params) { { user_id: other_user.id } }

        run_test!
      end
    end
  end

  path "/api/v1/organizations/{organization_id}/chat_channels" do
    parameter name: :organization_id, in: :path, type: :integer

    get "Lists organization chat channels" do
      tags "Chat Channels"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "200", "channels returned" do
        schema type: :array, items: { "$ref" => "#/components/schemas/chat_channel" }

        let(:organization) { create(:organization) }
        let(:organization_id) { organization.id }

        before do
          create(:organization_membership, user: current_user, organization:)
          Chats::ChannelCreator.call(organization:, created_by: current_user, attributes: { name: "general" })
        end

        run_test!
      end
    end

    post "Creates a organization chat channel" do
      tags "Chat Channels"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :request_params, in: :body, schema: { "$ref" => "#/components/schemas/chat_channel_request" }

      response "201", "channel created" do
        schema "$ref" => "#/components/schemas/chat_channel"

        let(:organization) { create(:organization) }
        let(:organization_id) { organization.id }
        let(:request_params) { { chat_channel: { name: "general", description: "Team chat" } } }

        before do
          create(:organization_membership, :admin, user: current_user, organization:)
        end

        run_test!
      end
    end
  end

  path "/api/v1/chat_channels/{id}" do
    parameter name: :id, in: :path, type: :integer

    patch "Updates a chat channel" do
      tags "Chat Channels"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :request_params, in: :body, schema: { "$ref" => "#/components/schemas/chat_channel_request" }

      response "200", "channel updated" do
        schema "$ref" => "#/components/schemas/chat_channel"

        let(:organization) { create(:organization) }
        let(:channel) { Chats::ChannelCreator.call(organization:, created_by: current_user, attributes: { name: "general" }) }
        let(:id) { channel.id }
        let(:request_params) { { chat_channel: { name: "planning" } } }

        before do
          create(:organization_membership, :admin, user: current_user, organization:)
        end

        run_test!
      end
    end

    delete "Deletes a chat channel" do
      tags "Chat Channels"
      security [ bearer_auth: [] ]

      response "204", "channel deleted" do
        let(:organization) { create(:organization) }
        let(:channel) { Chats::ChannelCreator.call(organization:, created_by: current_user, attributes: { name: "general" }) }
        let(:id) { channel.id }

        before do
          create(:organization_membership, :admin, user: current_user, organization:)
        end

        run_test!
      end
    end
  end

  path "/api/v1/chats/conversations/{conversation_id}/messages" do
    parameter name: :conversation_id, in: :path, type: :integer

    get "Lists chat messages" do
      tags "Chat Messages"
      security [ bearer_auth: [] ]
      produces "application/json"
      parameter name: :before_id, in: :query, type: :integer, required: false
      parameter name: :limit, in: :query, type: :integer, required: false

      response "200", "messages returned" do
        schema type: :array, items: { "$ref" => "#/components/schemas/chat_message" }

        let(:other_user) { create(:user) }
        let(:conversation) { Chats::DirectConversationFinder.call(current_user:, other_user:) }
        let(:conversation_id) { conversation.id }
        let(:before_id) { nil }
        let(:limit) { nil }

        before do
          create(:chat_message, chat_conversation: conversation, author: current_user)
        end

        run_test!
      end
    end

    post "Creates a chat message" do
      tags "Chat Messages"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"
      parameter name: :request_params, in: :body, schema: { "$ref" => "#/components/schemas/chat_message_request" }

      response "201", "message created" do
        schema "$ref" => "#/components/schemas/chat_message"

        let(:other_user) { create(:user) }
        let(:conversation) { Chats::DirectConversationFinder.call(current_user:, other_user:) }
        let(:conversation_id) { conversation.id }
        let(:request_params) { { message: { body: "Hello **world**" } } }

        run_test!
      end
    end
  end

  path "/api/v1/chats/messages/{id}/thread" do
    parameter name: :id, in: :path, type: :integer

    post "Creates or returns a message thread" do
      tags "Chat Messages"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "201", "thread conversation returned" do
        schema "$ref" => "#/components/schemas/chat_conversation"

        let(:other_user) { create(:user) }
        let(:conversation) { Chats::DirectConversationFinder.call(current_user:, other_user:) }
        let(:message) { create(:chat_message, chat_conversation: conversation, author: current_user) }
        let(:id) { message.id }

        run_test!
      end
    end
  end
end
# rubocop:enable RSpec/NestedGroups, RSpec/RepeatedExampleGroupBody, RSpec/VariableName, RSpec/MultipleMemoizedHelpers

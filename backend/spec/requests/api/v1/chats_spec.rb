require "rails_helper"

# rubocop:disable RSpec/ExampleLength
RSpec.describe "Api::V1::Chats", type: :request do
  describe "POST /api/v1/chats/direct_conversations" do
    it "creates a unique direct conversation for two users" do
      current_user = create(:user)
      other_user = create(:user)

      post "/api/v1/chats/direct_conversations",
        params: { user_id: other_user.id },
        headers: auth_headers_for(current_user)

      expect(response).to have_http_status(:created)
      expect(json_response["kind"]).to eq("direct")
      expect(json_response["participants"].pluck("id")).to contain_exactly(current_user.id, other_user.id)

      post "/api/v1/chats/direct_conversations",
        params: { user_id: other_user.id },
        headers: auth_headers_for(current_user)

      expect(response).to have_http_status(:created)
      expect(ChatConversation.where(kind: "direct").count).to eq(1)
    end

    it "rejects direct conversations with yourself" do
      current_user = create(:user)

      post "/api/v1/chats/direct_conversations",
        params: { user_id: current_user.id },
        headers: auth_headers_for(current_user)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response.dig("errors", "base")).to be_present
    end
  end

  describe "GET /api/v1/chats/conversations" do
    it "lists accessible direct and channel conversations but not threads" do
      current_user = create(:user)
      other_user = create(:user)
      organization = create(:organization)
      inaccessible_organization = create(:organization)
      create(:organization_membership, user: current_user, organization:)
      direct = Chats::DirectConversationFinder.call(current_user:, other_user:)
      channel = Chats::ChannelCreator.call(organization:, created_by: current_user, attributes: { name: "general" })
      parent = create(:chat_message, chat_conversation: direct, author: current_user)
      Chats::ThreadCreator.call(parent_message: parent, created_by: current_user)
      Chats::ChannelCreator.call(organization: inaccessible_organization, created_by: other_user, attributes: { name: "private" })

      get "/api/v1/chats/conversations", headers: auth_headers_for(current_user)

      expect(response).to have_http_status(:ok)
      expect(json_response.pluck("id")).to contain_exactly(direct.id, channel.chat_conversation_id)
    end
  end

  describe "chat channels" do
    it "allows organization admins to create, update, and delete channels" do
      current_user = create(:user)
      organization = create(:organization)
      create(:organization_membership, :admin, user: current_user, organization:)

      post "/api/v1/organizations/#{organization.id}/chat_channels",
        params: { chat_channel: { name: "general", description: "Team chat" } },
        headers: auth_headers_for(current_user)

      expect(response).to have_http_status(:created)
      channel_id = json_response["id"]
      conversation_id = json_response["conversation_id"]

      patch "/api/v1/chat_channels/#{channel_id}",
        params: { chat_channel: { name: "planning" } },
        headers: auth_headers_for(current_user)

      expect(response).to have_http_status(:ok)
      expect(json_response["name"]).to eq("planning")

      delete "/api/v1/chat_channels/#{channel_id}", headers: auth_headers_for(current_user)

      expect(response).to have_http_status(:no_content)
      expect(ChatConversation.exists?(conversation_id)).to be(false)
    end

    it "prevents ordinary organization members from creating channels" do
      current_user = create(:user)
      organization = create(:organization)
      create(:organization_membership, user: current_user, organization:)

      post "/api/v1/organizations/#{organization.id}/chat_channels",
        params: { chat_channel: { name: "general" } },
        headers: auth_headers_for(current_user)

      expect(response).to have_http_status(:forbidden)
    end

    it "lists channels for organization members" do
      current_user = create(:user)
      admin = create(:user)
      organization = create(:organization)
      create(:organization_membership, user: current_user, organization:)
      create(:organization_membership, :admin, user: admin, organization:)
      channel = Chats::ChannelCreator.call(organization:, created_by: admin, attributes: { name: "general" })

      get "/api/v1/organizations/#{organization.id}/chat_channels", headers: auth_headers_for(current_user)

      expect(response).to have_http_status(:ok)
      expect(json_response.pluck("conversation_id")).to eq([ channel.chat_conversation_id ])
    end
  end

  describe "messages" do
    it "posts and paginates messages in ascending response order" do
      current_user = create(:user)
      other_user = create(:user)
      conversation = Chats::DirectConversationFinder.call(current_user:, other_user:)
      first = create(:chat_message, chat_conversation: conversation, author: current_user, body: "first")
      second = create(:chat_message, chat_conversation: conversation, author: other_user, body: "second")

      post "/api/v1/chats/conversations/#{conversation.id}/messages",
        params: { message: { body: "## third" } },
        headers: auth_headers_for(current_user)

      expect(response).to have_http_status(:created)
      expect(json_response["body"]).to eq("## third")

      get "/api/v1/chats/conversations/#{conversation.id}/messages",
        params: { before_id: json_response["id"], limit: 2 },
        headers: auth_headers_for(current_user)

      expect(response).to have_http_status(:ok)
      expect(json_response.pluck("id")).to eq([ first.id, second.id ])
    end

    it "does not expose direct messages to non-participants" do
      current_user = create(:user)
      other_user = create(:user)
      outsider = create(:user)
      conversation = Chats::DirectConversationFinder.call(current_user:, other_user:)

      get "/api/v1/chats/conversations/#{conversation.id}/messages",
        headers: auth_headers_for(outsider)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/chats/messages/:id/thread" do
    it "creates a thread for a top-level message idempotently" do
      current_user = create(:user)
      other_user = create(:user)
      conversation = Chats::DirectConversationFinder.call(current_user:, other_user:)
      message = create(:chat_message, chat_conversation: conversation, author: current_user)

      post "/api/v1/chats/messages/#{message.id}/thread", headers: auth_headers_for(current_user)

      expect(response).to have_http_status(:created)
      thread_id = json_response["id"]
      expect(json_response["kind"]).to eq("thread")
      expect(json_response.dig("parent_message", "id")).to eq(message.id)

      post "/api/v1/chats/messages/#{message.id}/thread", headers: auth_headers_for(current_user)

      expect(response).to have_http_status(:ok)
      expect(json_response["id"]).to eq(thread_id)
    end

    it "prevents creating nested threads" do
      current_user = create(:user)
      other_user = create(:user)
      conversation = Chats::DirectConversationFinder.call(current_user:, other_user:)
      message = create(:chat_message, chat_conversation: conversation, author: current_user)
      thread = Chats::ThreadCreator.call(parent_message: message, created_by: current_user)
      reply = create(:chat_message, chat_conversation: thread, author: current_user)

      post "/api/v1/chats/messages/#{reply.id}/thread", headers: auth_headers_for(current_user)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
# rubocop:enable RSpec/ExampleLength

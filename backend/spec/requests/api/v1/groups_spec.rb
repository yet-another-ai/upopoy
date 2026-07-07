require "rails_helper"

RSpec.describe "Api::V1::Groups", type: :request do
  describe "GET /api/v1/groups" do
    it "lists groups with parent and member information" do
      user = create(:user)
      parent = create(:group, name: "Engineering")
      group = create(:group, name: "Platform", parent_group: parent)
      create(:group_membership, user:, group: parent)
      create(:group_membership, user:, group:)

      get "/api/v1/groups", headers: auth_headers_for(user)

      platform = json_response.find { |item| item["name"] == "Platform" }
      expect(platform["parent_group_id"]).to eq(parent.id)
      expect(platform["parent_group_name"]).to eq("Engineering")
      expect(platform["user_ids"]).to eq([ user.id ])
    end

    it "lists descendant groups for ancestor members" do
      user = create(:user)
      parent = create(:group, name: "Engineering")
      child = create(:group, name: "Platform", parent_group: parent)
      create(:group_membership, user:, group: parent)

      get "/api/v1/groups", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response.pluck("id")).to include(parent.id, child.id)
      platform = json_response.find { |item| item["id"] == child.id }
      expect(platform["user_ids"]).to eq([])
      expect(platform["parent_group_name"]).to eq("Engineering")
    end

    it "requires authentication" do
      get "/api/v1/groups"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/groups" do
    it "creates a group with members" do
      user = create(:user)
      member = create(:user)
      group_params = {
        group: { name: "Product", description: "Product planning", user_ids: [ member.id ] }
      }

      post "/api/v1/groups",
           params: group_params,
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:created)
      expect(json_response["name"]).to eq("Product")
      expect(json_response["user_ids"]).to contain_exactly(user.id, member.id)
    end

    it "does not create a child group under an inaccessible parent" do
      user = create(:user)
      parent = create(:group)

      post "/api/v1/groups",
           params: { group: { name: "Private child", parent_group_id: parent.id } },
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end

    it "creates a child group under an inherited parent" do
      user = create(:user)
      parent = create(:group)
      child = create(:group, parent_group: parent)
      create(:group_membership, user:, group: parent)

      post "/api/v1/groups",
           params: { group: { name: "Nested", parent_group_id: child.id } },
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:created)
      expect(json_response["parent_group_id"]).to eq(child.id)
    end
  end

  describe "PATCH /api/v1/groups/:id" do
    it "updates group attributes and members" do
      user = create(:user)
      member = create(:user)
      group = create(:group)
      create(:group_membership, user:, group:)
      group_params = { group: { name: "Renamed", user_ids: [ member.id ] } }

      patch "/api/v1/groups/#{group.id}",
            params: group_params,
            headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response["name"]).to eq("Renamed")
      expect(json_response["user_ids"]).to eq([ member.id ])
    end

    it "rejects parent cycles" do
      user = create(:user)
      parent = create(:group)
      child = create(:group, parent_group: parent)
      create(:group_membership, user:, group: parent)
      create(:group_membership, user:, group: child)

      patch "/api/v1/groups/#{parent.id}",
            params: { group: { parent_group_id: child.id } },
            headers: auth_headers_for(user)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response.dig("errors", "parent_group").join).to include("cannot be a child group")
    end

    it "does not update a group for non-members" do
      user = create(:user)
      group = create(:group)

      patch "/api/v1/groups/#{group.id}",
            params: { group: { name: "Renamed" } },
            headers: auth_headers_for(user)

      expect(response).to have_http_status(:not_found)
    end

    it "updates a descendant group for ancestor members" do
      user = create(:user)
      parent = create(:group)
      child = create(:group, parent_group: parent)
      create(:group_membership, user:, group: parent)

      patch "/api/v1/groups/#{child.id}",
            params: { group: { name: "Renamed child" } },
            headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response["name"]).to eq("Renamed child")
    end
  end

  describe "DELETE /api/v1/groups/:id" do
    it "deletes a group" do
      user = create(:user)
      group = create(:group)
      create(:group_membership, user:, group:)

      expect {
        delete "/api/v1/groups/#{group.id}", headers: auth_headers_for(user)
      }.to change(Group, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end

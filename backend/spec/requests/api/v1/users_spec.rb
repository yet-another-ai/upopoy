require "rails_helper"

RSpec.describe "Api::V1::Users", type: :request do
  describe "GET /api/v1/users" do
    it "lists paginated users with group membership ids" do
      user = create(:user, email: "ada@example.com")
      other_user = create(:user, email: "grace@example.com")
      group = create(:group)
      create(:group_membership, user: other_user, group:)

      get "/api/v1/users", params: { page: 1, per_page: 1 }, headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response.dig("meta", "total_count")).to eq(2)
      expect(json_response.dig("meta", "per_page")).to eq(1)
      expect(json_response["users"].pluck("email")).to eq([ "ada@example.com" ])

      get "/api/v1/users", params: { page: 2, per_page: 1 }, headers: auth_headers_for(user)

      expect(json_response["users"].first["group_ids"]).to eq([ group.id ])
      expect(json_response["users"].first["groups_count"]).to eq(1)
    end

    it "requires authentication" do
      get "/api/v1/users"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/users/:id" do
    it "updates user profile fields" do
      user = create(:user)
      user_params = {
        email: "new@example.com",
        display_name: "Grace Hopper",
        title: "Admiral",
        bio: "Compiler pioneer."
      }

      patch "/api/v1/users/#{user.id}",
            params: { user: user_params },
            headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response).to include(user_params.stringify_keys)
    end

    it "updates profile skills" do
      user = create(:user)
      skills = [
        { name: "Product discovery", level: "advanced", note: "Led 12 customer interviews." },
        { name: "Rails", level: "working", note: "" }
      ]

      patch "/api/v1/users/#{user.id}",
            params: { user: { email: user.email, skills: } },
            headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response["skills"]).to eq(JSON.parse(skills.to_json))
    end

    it "rejects invalid profile skill levels" do
      user = create(:user)
      user_params = { email: user.email, skills: [ { name: "Rails", level: "legendary", note: "" } ] }

      patch "/api/v1/users/#{user.id}",
            params: { user: user_params },
            headers: auth_headers_for(user)

      expect(response).to have_http_status(422)
      expect(json_response.dig("errors", "skills")).to include("Skills level is invalid")
    end

    it "normalizes blank profile skill names" do
      user = create(:user)
      skills = [
        { name: " ", level: "advanced", note: "Ignored" },
        { name: "Rails", level: "working", note: "" }
      ]

      patch "/api/v1/users/#{user.id}",
            params: { user: { email: user.email, skills: } },
            headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response["skills"]).to eq([ { "name" => "Rails", "level" => "working", "note" => "" } ])
    end

    it "does not allow regular users to update another profile" do
      user, target = create(:user), create(:user)

      patch "/api/v1/users/#{target.id}",
            params: { user: { email: "new@example.com" } },
            headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
      expect(target.reload.email).not_to eq("new@example.com")
    end

    it "allows system admins to update another profile" do
      user = create(:user, :system_admin)
      target = create(:user)

      patch "/api/v1/users/#{target.id}",
            params: { user: { email: "new@example.com" } },
            headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(target.reload.email).to eq("new@example.com")
    end

    it "allows system admins to update system admin status" do
      user = create(:user, :system_admin)
      target = create(:user)

      patch "/api/v1/users/#{target.id}",
            params: { user: { email: target.email, system_admin: true } },
            headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response["system_admin"]).to be(true)
      expect(target.reload).to be_system_admin
    end

    it "does not allow regular users to update system admin status" do
      user = create(:user)

      patch "/api/v1/users/#{user.id}",
            params: { user: { email: user.email, system_admin: true } },
            headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response["system_admin"]).to be(false)
      expect(user.reload).not_to be_system_admin
    end
  end

  describe "GET /api/v1/users/:id" do
    it "returns a managed user profile" do
      user = create(:user)
      target = create(:user, display_name: "Ada Lovelace")

      get "/api/v1/users/#{target.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response["display_name"]).to eq("Ada Lovelace")
    end
  end
end

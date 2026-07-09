require "rails_helper"

RSpec.describe "Api::V1::Organizations", type: :request do
  describe "GET /api/v1/organizations" do
    it "lists organizations the user belongs to with member information" do
      user = create(:user)
      organization = create(:organization, name: "Engineering")
      create(:organization, name: "Private")
      create(:organization_membership, user:, organization:)

      get "/api/v1/organizations", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response.pluck("name")).to eq([ "Engineering" ])
      expect(json_response.first["user_ids"]).to eq([ user.id ])
    end

    it "allows system admins to list all organizations" do
      user = create(:user, :system_admin)
      create(:organization, name: "Engineering")
      create(:organization, name: "Product")

      get "/api/v1/organizations", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response.pluck("name")).to eq(%w[Engineering Product])
    end
  end

  describe "POST /api/v1/organizations" do
    it "creates an organization with the current user as an admin" do
      user = create(:user)
      member = create(:user)

      post "/api/v1/organizations",
        params: { organization: { name: "Product", description: "Planning", user_ids: [ member.id ] } },
        headers: auth_headers_for(user)

      expect(response).to have_http_status(:created)
      expect(json_response["name"]).to eq("Product")
      expect(json_response["user_ids"]).to contain_exactly(user.id, member.id)
      expect(json_response["admin_user_ids"]).to contain_exactly(user.id)
    end

    it "rejects unknown user ids" do
      user = create(:user)

      post "/api/v1/organizations",
        params: { organization: { name: "Product", user_ids: [ 123_456 ] } },
        headers: auth_headers_for(user)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /api/v1/organizations/:id" do
    it "updates organization attributes, members, and admins" do
      user = create(:user)
      member = create(:user)
      organization = create(:organization)
      create(:organization_membership, :admin, user:, organization:)

      patch "/api/v1/organizations/#{organization.id}",
        params: { organization: { name: "Renamed", user_ids: [ member.id ], admin_user_ids: [ member.id ] } },
        headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response["name"]).to eq("Renamed")
      expect(json_response["user_ids"]).to eq([ member.id ])
      expect(json_response["admin_user_ids"]).to eq([ member.id ])
    end

    it "does not update an organization for ordinary members" do
      user = create(:user)
      organization = create(:organization)
      create(:organization_membership, user:, organization:, admin: false)

      patch "/api/v1/organizations/#{organization.id}",
        params: { organization: { name: "Renamed" } },
        headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects removing the final admin" do
      user = create(:user)
      organization = create(:organization)
      create(:organization_membership, :admin, user:, organization:)

      patch "/api/v1/organizations/#{organization.id}",
        params: { organization: { admin_user_ids: [] } },
        headers: auth_headers_for(user)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response.dig("errors", "admin_user_ids")).to be_present
    end
  end

  describe "DELETE /api/v1/organizations/:id" do
    it "deletes an organization for admins" do
      user = create(:user)
      organization = create(:organization)
      create(:organization_membership, :admin, user:, organization:)

      expect {
        delete "/api/v1/organizations/#{organization.id}", headers: auth_headers_for(user)
      }.to change(Organization, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end

require "rails_helper"

RSpec.describe "PgHero", type: :request do
  self.use_transactional_tests = false

  it "serves the PgHero dashboard" do
    get "/pghero"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("PgHero")
    expect(response.body).to include("/rails-assets/pghero/")
  end
end

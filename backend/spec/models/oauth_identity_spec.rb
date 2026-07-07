require "rails_helper"

RSpec.describe OauthIdentity, type: :model do
  it "requires a provider" do
    identity = build(:oauth_identity, provider: nil)

    expect(identity).not_to be_valid
    expect(identity.errors[:provider]).to be_present
  end

  it "requires a uid" do
    identity = build(:oauth_identity, uid: nil)

    expect(identity).not_to be_valid
    expect(identity.errors[:uid]).to be_present
  end

  it "requires a unique uid per provider" do
    create(:oauth_identity, provider: "developer", uid: "42")
    identity = build(:oauth_identity, provider: "developer", uid: "42")

    expect(identity).not_to be_valid
    expect(identity.errors[:uid]).to be_present
  end
end

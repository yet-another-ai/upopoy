require "rails_helper"

RSpec.describe ChatChannel, type: :model do
  it "requires names to be unique within a organization case-insensitively" do
    organization = create(:organization)
    create(:chat_channel, organization:, name: "General")

    duplicate = build(:chat_channel, organization:, name: "general")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:name]).to be_present
  end
end

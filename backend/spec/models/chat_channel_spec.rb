require "rails_helper"

RSpec.describe ChatChannel, type: :model do
  it "requires names to be unique within a group case-insensitively" do
    group = create(:group)
    create(:chat_channel, group:, name: "General")

    duplicate = build(:chat_channel, group:, name: "general")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:name]).to be_present
  end
end

require "rails_helper"

RSpec.describe ChatMessage, type: :model do
  it "requires a markdown body" do
    message = build(:chat_message, body: "")

    expect(message).not_to be_valid
    expect(message.errors[:body]).to be_present
  end

  it "updates the conversation last message timestamp" do
    conversation = create(:chat_conversation, :direct)

    message = create(:chat_message, chat_conversation: conversation)

    expect(conversation.reload.last_message_at.to_i).to eq(message.created_at.to_i)
  end
end

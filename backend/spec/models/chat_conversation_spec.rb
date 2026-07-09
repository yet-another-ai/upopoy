require "rails_helper"

RSpec.describe ChatConversation, type: :model do
  it "requires unique direct keys for direct conversations" do
    create(:chat_conversation, :direct, direct_key: "1:2")

    duplicate = build(:chat_conversation, :direct, direct_key: "1:2")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:direct_key]).to be_present
  end

  it "requires a unique top-level parent message for threads" do
    parent_message = create(:chat_message)
    create(:chat_conversation, :thread, parent_message:)

    duplicate = build(:chat_conversation, :thread, parent_message:)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:parent_message_id]).to be_present
  end

  it "does not allow a thread to be created from a thread reply" do
    parent_message = create(:chat_message)
    thread = create(:chat_conversation, :thread, parent_message:)
    reply = create(:chat_message, chat_conversation: thread)

    nested_thread = build(:chat_conversation, :thread, parent_message: reply)

    expect(nested_thread).not_to be_valid
    expect(nested_thread.errors[:parent_message]).to be_present
  end
end

class ChatConversationParticipant < ApplicationRecord
  belongs_to :chat_conversation
  belongs_to :user

  validates :user_id, uniqueness: { scope: :chat_conversation_id }
  validate :conversation_must_be_direct

  private

  def conversation_must_be_direct
    return if chat_conversation.blank? || chat_conversation.direct?

    errors.add(:chat_conversation, "must be a direct conversation")
  end
end

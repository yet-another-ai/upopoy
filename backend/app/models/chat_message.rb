class ChatMessage < ApplicationRecord
  belongs_to :chat_conversation
  belongs_to :author, class_name: "User"
  has_one :thread_conversation,
          class_name: "ChatConversation",
          foreign_key: :parent_message_id,
          dependent: :destroy,
          inverse_of: :parent_message

  validates :body, presence: true

  after_create_commit :touch_conversation_last_message_at

  private

  def touch_conversation_last_message_at
    chat_conversation.update_column(:last_message_at, created_at)
  end
end

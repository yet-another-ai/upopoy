class ChatChannel < ApplicationRecord
  belongs_to :group
  belongs_to :chat_conversation
  belongs_to :created_by, class_name: "User"

  validates :name, presence: true, uniqueness: { scope: :group_id, case_sensitive: false }
  validates :chat_conversation_id, uniqueness: true
  validate :conversation_must_be_channel

  before_validation :normalize_name

  private

  def normalize_name
    self.name = name.to_s.strip
  end

  def conversation_must_be_channel
    return if chat_conversation.blank? || chat_conversation.channel?

    errors.add(:chat_conversation, "must be a channel conversation")
  end
end

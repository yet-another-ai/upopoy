class ChatConversation < ApplicationRecord
  KINDS = %w[ direct channel thread ].freeze

  belongs_to :organization, optional: true
  belongs_to :parent_message,
             class_name: "ChatMessage",
             optional: true,
             inverse_of: :thread_conversation
  belongs_to :created_by, class_name: "User"

  has_one :chat_channel, dependent: :destroy
  has_many :chat_conversation_participants, dependent: :destroy
  has_many :participants, through: :chat_conversation_participants, source: :user
  has_many :chat_messages, dependent: :destroy

  validates :kind, presence: true, inclusion: { in: KINDS }
  validates :direct_key, presence: true, uniqueness: true, if: :direct?
  validates :direct_key, absence: true, unless: :direct?
  validates :organization, presence: true, if: :channel?
  validates :parent_message, presence: true, if: :thread?
  validates :parent_message_id, uniqueness: true, allow_nil: true
  validate :thread_parent_must_be_top_level

  scope :visible_to, lambda { |user|
    return none if user.blank?

    direct_ids = ChatConversationParticipant.where(user:).select(:chat_conversation_id)
    organization_ids = user.system_admin? ? Organization.select(:id) : OrganizationMembership.accessible_organization_ids_for(user)
    parent_conversation_ids = ChatConversation
      .where(id: direct_ids)
      .or(ChatConversation.where(kind: "channel", organization_id: organization_ids))
      .select(:id)
    parent_message_ids = ChatMessage.where(chat_conversation_id: parent_conversation_ids).select(:id)

    where(id: direct_ids)
      .or(where(kind: "channel", organization_id: organization_ids))
      .or(where(kind: "thread", parent_message_id: parent_message_ids))
  }

  def direct?
    kind == "direct"
  end

  def channel?
    kind == "channel"
  end

  def thread?
    kind == "thread"
  end

  private

  def thread_parent_must_be_top_level
    return unless thread? && parent_message&.chat_conversation&.thread?

    errors.add(:parent_message, "must belong to a direct or channel conversation")
  end
end

module Chats
  class DirectConversationFinder
    def self.call(current_user:, other_user:)
      new(current_user:, other_user:).call
    end

    def initialize(current_user:, other_user:)
      @current_user = current_user
      @other_user = other_user
    end

    def call
      raise ActiveRecord::RecordInvalid, invalid_conversation if current_user.id == other_user.id

      ChatConversation.find_by(direct_key:) || create_conversation
    rescue ActiveRecord::RecordNotUnique
      ChatConversation.find_by!(direct_key:)
    end

    private

    attr_reader :current_user, :other_user

    def create_conversation
      ChatConversation.transaction do
        conversation = ChatConversation.create!(
          kind: "direct",
          direct_key:,
          created_by: current_user
        )
        participant_ids.each do |user_id|
          conversation.chat_conversation_participants.create!(user_id:)
        end
        conversation
      end
    end

    def direct_key
      @direct_key ||= participant_ids.join(":")
    end

    def participant_ids
      @participant_ids ||= [ current_user.id, other_user.id ].sort
    end

    def invalid_conversation
      conversation = ChatConversation.new(kind: "direct", created_by: current_user)
      conversation.errors.add(:base, "Cannot create a direct conversation with yourself")
      conversation
    end
  end
end

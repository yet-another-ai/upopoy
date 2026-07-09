module Chats
  class ChannelCreator
    def self.call(group:, created_by:, attributes:)
      new(group:, created_by:, attributes:).call
    end

    def initialize(group:, created_by:, attributes:)
      @group = group
      @created_by = created_by
      @attributes = attributes
    end

    def call
      ChatConversation.transaction do
        conversation = group.chat_conversations.create!(
          kind: "channel",
          created_by:
        )
        group.chat_channels.create!(
          attributes.merge(chat_conversation: conversation, created_by:)
        )
      end
    end

    private

    attr_reader :group, :created_by, :attributes
  end
end

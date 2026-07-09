module Chats
  class ChannelCreator
    def self.call(organization:, created_by:, attributes:)
      new(organization:, created_by:, attributes:).call
    end

    def initialize(organization:, created_by:, attributes:)
      @organization = organization
      @created_by = created_by
      @attributes = attributes
    end

    def call
      ChatConversation.transaction do
        conversation = organization.chat_conversations.create!(
          kind: "channel",
          created_by:
        )
        organization.chat_channels.create!(
          attributes.merge(chat_conversation: conversation, created_by:)
        )
      end
    end

    private

    attr_reader :organization, :created_by, :attributes
  end
end

module Chats
  class ThreadCreator
    def self.call(parent_message:, created_by:)
      new(parent_message:, created_by:).call
    end

    def initialize(parent_message:, created_by:)
      @parent_message = parent_message
      @created_by = created_by
    end

    def call
      existing_thread || create_thread
    rescue ActiveRecord::RecordNotUnique
      existing_thread || raise
    end

    private

    attr_reader :parent_message, :created_by

    def existing_thread
      parent_message.thread_conversation
    end

    def create_thread
      ChatConversation.create!(
        kind: "thread",
        parent_message:,
        created_by:
      )
    end
  end
end

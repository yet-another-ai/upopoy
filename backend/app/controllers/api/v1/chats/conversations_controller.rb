module Api
  module V1
    module Chats
      class ConversationsController < BaseController
        before_action :set_conversation, only: [ :show ]

        def index
          @conversations = policy_scope(ChatConversation)
            .where(kind: %w[ direct channel ])
            .includes(:group, :participants, :chat_channel, parent_message: :author)
            .order(Arel.sql("last_message_at DESC NULLS LAST"), created_at: :desc)
        end

        def show
          authorize @conversation
        end

        private

        def set_conversation
          @conversation = policy_scope(ChatConversation)
            .includes(:group, :participants, :chat_channel, parent_message: :author)
            .find(params[:id])
        end
      end
    end
  end
end

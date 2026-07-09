module Api
  module V1
    module Chats
      class MessagesController < BaseController
        before_action :set_conversation, only: [ :index, :create ]
        before_action :set_message, only: [ :thread ]

        def index
          authorize @conversation, :show?
          scoped_messages = policy_scope(@conversation.chat_messages)
            .includes(:author, thread_conversation: :chat_messages)
            .order(id: :desc)
            .limit(limit_param)
          scoped_messages = scoped_messages.where("chat_messages.id < ?", params[:before_id]) if params[:before_id].present?

          @messages = scoped_messages.to_a.reverse
        end

        def create
          authorize @conversation, :create_message?

          @message = @conversation.chat_messages.new(message_params.merge(author: current_user))
          if @message.save
            render :show, status: :created
          else
            render_errors(@message)
          end
        end

        def thread
          authorize @message, :create_thread?

          existing_thread = @message.thread_conversation
          @conversation = ::Chats::ThreadCreator.call(parent_message: @message, created_by: current_user)
          render "api/v1/chats/conversations/show", status: existing_thread ? :ok : :created
        end

        private

        def set_conversation
          @conversation = policy_scope(ChatConversation).find(params[:conversation_id])
        end

        def set_message
          @message = policy_scope(ChatMessage).find(params[:id])
        end

        def message_params
          params.require(:message).permit(:body)
        end

        def limit_param
          params.fetch(:limit, 50).to_i.clamp(1, 100)
        end
      end
    end
  end
end

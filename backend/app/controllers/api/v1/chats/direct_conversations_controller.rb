module Api
  module V1
    module Chats
      class DirectConversationsController < BaseController
        def create
          other_user = policy_scope(User).find(params.require(:user_id))
          @conversation = ::Chats::DirectConversationFinder.call(
            current_user:,
            other_user:
          )
          authorize @conversation, :show?
          render "api/v1/chats/conversations/show", status: :created
        rescue ActiveRecord::RecordInvalid => e
          skip_authorization
          render_errors(e.record)
        end
      end
    end
  end
end

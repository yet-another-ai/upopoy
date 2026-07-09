class ChatMessagePolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    conversation_visible?
  end

  def create_thread?
    conversation_visible? && !record.chat_conversation.thread?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?

      scope.joins(:chat_conversation)
        .where(chat_conversations: { id: ChatConversation.visible_to(user).select(:id) })
    end
  end

  private

  def conversation_visible?
    return false if user.blank? || record.blank?

    ChatConversation.visible_to(user).where(id: record.chat_conversation_id).exists?
  end
end

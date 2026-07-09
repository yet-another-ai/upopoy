class ChatConversationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    visible?
  end

  def create_message?
    visible?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.visible_to(user)
    end
  end

  private

  def visible?
    return false if user.blank? || record.blank?

    ChatConversation.visible_to(user).where(id: record.id).exists?
  end
end

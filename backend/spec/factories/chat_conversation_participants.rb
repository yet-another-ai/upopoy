FactoryBot.define do
  factory :chat_conversation_participant do
    association :chat_conversation, :direct
    association :user
  end
end

FactoryBot.define do
  factory :chat_message do
    association :chat_conversation, :direct
    association :author, factory: :user
    body { "Hello **world**" }
  end
end

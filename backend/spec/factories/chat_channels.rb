FactoryBot.define do
  factory :chat_channel do
    association :group
    association :chat_conversation, :channel
    association :created_by, factory: :user
    sequence(:name) { |index| "general-#{index}" }
    description { "Team discussion" }

    after(:build) do |channel|
      channel.chat_conversation.group ||= channel.group
      channel.chat_conversation.created_by ||= channel.created_by
    end
  end
end

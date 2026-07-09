thread_conversation = message.thread_conversation

json.extract! message, :id, :chat_conversation_id, :body, :created_at, :updated_at
json.conversation_id message.chat_conversation_id
json.author do
  json.partial! "api/v1/users/user", user: message.author
end
json.thread_conversation_id thread_conversation&.id
json.thread_reply_count thread_conversation ? thread_conversation.chat_messages.size : 0
json.thread_last_message_at thread_conversation&.last_message_at

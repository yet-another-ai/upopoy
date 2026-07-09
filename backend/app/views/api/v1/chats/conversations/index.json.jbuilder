json.array! @conversations do |conversation|
  json.partial! "api/v1/chats/conversations/conversation", conversation: conversation, viewer: current_user
end

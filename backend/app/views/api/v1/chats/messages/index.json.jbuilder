json.array! @messages do |message|
  json.partial! "api/v1/chats/messages/message", message: message
end

json.array! @chat_channels do |chat_channel|
  json.partial! "api/v1/chat_channels/chat_channel", chat_channel: chat_channel, viewer: current_user
end

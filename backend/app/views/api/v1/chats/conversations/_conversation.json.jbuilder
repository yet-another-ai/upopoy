channel = conversation.chat_channel
participants = conversation.participants.to_a
other_participant = participants.find { |participant| participant.id != viewer.id } || participants.first
parent_message = conversation.parent_message
title =
  if conversation.direct?
    other_participant&.display_name.presence || other_participant&.email || "Direct message"
  elsif conversation.channel?
    channel&.name || "Channel"
  else
    "Thread"
  end

json.extract! conversation, :id, :kind, :organization_id, :last_message_at, :created_at, :updated_at
json.title title
json.organization_name conversation.organization&.name
json.channel_id channel&.id
json.channel_name channel&.name
json.can_manage conversation.channel? && conversation.organization_id.present? && viewer.can_admin_organization?(conversation.organization_id)
json.participants participants do |participant|
  json.partial! "api/v1/users/user", user: participant
end
json.parent_message do
  if parent_message
    json.partial! "api/v1/chats/messages/message", message: parent_message
  else
    json.null!
  end
end
json.other_participant do
  if conversation.direct? && other_participant
    json.partial! "api/v1/users/user", user: other_participant
  else
    json.null!
  end
end

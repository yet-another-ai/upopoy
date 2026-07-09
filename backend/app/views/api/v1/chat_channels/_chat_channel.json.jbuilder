json.extract! chat_channel, :id, :organization_id, :name, :description, :created_at, :updated_at
json.conversation_id chat_channel.chat_conversation_id
json.can_manage viewer.can_admin_organization?(chat_channel.organization_id)

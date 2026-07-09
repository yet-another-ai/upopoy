json.extract! chat_channel, :id, :group_id, :name, :description, :created_at, :updated_at
json.conversation_id chat_channel.chat_conversation_id
json.can_manage viewer.can_admin_group?(chat_channel.group_id)

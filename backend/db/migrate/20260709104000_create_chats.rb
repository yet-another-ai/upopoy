class CreateChats < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_conversations do |t|
      t.string :kind, null: false
      t.string :direct_key
      t.references :group, foreign_key: true
      t.bigint :parent_message_id
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.datetime :last_message_at

      t.timestamps
    end

    add_index :chat_conversations, :kind
    add_index :chat_conversations, :direct_key, unique: true, where: "direct_key IS NOT NULL"
    add_index :chat_conversations, :parent_message_id, unique: true, where: "parent_message_id IS NOT NULL"
    add_index :chat_conversations, [ :group_id, :kind ]

    create_table :chat_conversation_participants do |t|
      t.references :chat_conversation,
        null: false,
        foreign_key: { on_delete: :cascade },
        index: false
      t.references :user, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :chat_conversation_participants,
      [ :chat_conversation_id, :user_id ],
      unique: true,
      name: "index_chat_participants_on_conversation_and_user"

    create_table :chat_channels do |t|
      t.references :group, null: false, foreign_key: { on_delete: :cascade }
      t.references :chat_conversation,
        null: false,
        foreign_key: { on_delete: :cascade },
        index: { unique: true }
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.text :description

      t.timestamps
    end

    add_index :chat_channels,
      "group_id, lower((name)::text)",
      unique: true,
      name: "index_chat_channels_on_group_and_lower_name"

    create_table :chat_messages do |t|
      t.references :chat_conversation, null: false, foreign_key: { on_delete: :cascade }
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false

      t.timestamps
    end

    add_index :chat_messages, [ :chat_conversation_id, :id ]
    add_foreign_key :chat_conversations,
      :chat_messages,
      column: :parent_message_id,
      on_delete: :cascade
  end
end

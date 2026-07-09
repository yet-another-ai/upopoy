class CreateInitialSchema < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pg_stat_statements"
    enable_extension "pg_trgm"

    create_table :application_settings do |t|
      t.boolean :registration_enabled, default: true, null: false
      t.boolean :email_login_enabled, default: true, null: false
      t.integer :singleton_guard, default: 0, null: false
      t.timestamps
      t.index :singleton_guard, unique: true
    end

    create_table :users do |t|
      t.string :email, default: "", null: false
      t.string :encrypted_password, default: "", null: false
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.string :jti, null: false
      t.string :display_name
      t.string :title
      t.text :bio
      t.json :skills, default: [], null: false
      t.boolean :system_admin, default: false, null: false
      t.timestamps
      t.index :email, unique: true
      t.index :jti, unique: true
      t.index :reset_password_token, unique: true
    end

    create_table :oauth_identities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :uid, null: false
      t.timestamps
      t.index [ :provider, :uid ], unique: true
      t.index [ :user_id, :provider ], unique: true
    end

    create_table :organizations do |t|
      t.string :name, null: false
      t.text :description
      t.timestamps
    end

    create_table :organization_memberships do |t|
      t.references :organization, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.boolean :admin, default: false, null: false
      t.timestamps
      t.index [ :organization_id, :admin ]
      t.index [ :organization_id, :user_id ], unique: true
    end

    create_table :projects do |t|
      t.references :user, null: false, foreign_key: true
      t.string :owner_type, null: false
      t.bigint :owner_id, null: false
      t.string :name, null: false
      t.text :description
      t.timestamps
      t.index [ :owner_type, :owner_id ]
    end

    create_table :iterations do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.datetime :starts_at
      t.datetime :deadline
      t.boolean :inbox, default: false, null: false
      t.timestamps
      t.index [ :project_id, :inbox ], unique: true, where: "inbox = true"
    end

    create_table :tasks do |t|
      t.references :project, null: false, foreign_key: true
      t.references :iteration, foreign_key: { on_delete: :nullify }
      t.string :title, null: false
      t.text :description
      t.string :status, default: "todo", null: false
      t.string :priority, default: "medium", null: false
      t.integer :position, default: 0, null: false
      t.datetime :deadline
      t.integer :estimated_minutes
      t.timestamps
      t.index [ :project_id, :status, :position ]
    end

    create_table :task_developers, id: false do |t|
      t.references :task, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.index [ :task_id, :user_id ], unique: true
    end

    create_table :task_reviewers, id: false do |t|
      t.references :task, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.index [ :task_id, :user_id ], unique: true
    end

    create_table :drive_items do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.references :parent, foreign_key: { to_table: :drive_items, on_delete: :cascade }
      t.string :kind, null: false
      t.string :name, null: false
      t.text :text_content_cache, default: "", null: false
      t.datetime :deleted_at
      t.timestamps
      t.index [ :deleted_at ]
      t.index [ :project_id, :kind ]
      t.index "project_id, lower((name)::text)",
        name: "index_drive_items_on_project_root_name",
        unique: true,
        where: "parent_id IS NULL AND deleted_at IS NULL"
      t.index "project_id, parent_id, lower((name)::text)",
        name: "index_drive_items_on_project_parent_name",
        unique: true,
        where: "parent_id IS NOT NULL AND deleted_at IS NULL"
    end

    create_table :drive_item_versions do |t|
      t.references :drive_item, null: false, foreign_key: { on_delete: :cascade }
      t.integer :version_number, null: false
      t.string :name, null: false
      t.string :content_type
      t.bigint :byte_size
      t.text :text_content_cache, default: "", null: false
      t.timestamps
      t.index [ :drive_item_id, :version_number ], unique: true
    end

    create_table :active_storage_blobs do |t|
      t.string :key, null: false
      t.string :filename, null: false
      t.string :content_type
      t.text :metadata
      t.string :service_name, null: false
      t.bigint :byte_size, null: false
      t.string :checksum
      t.datetime :created_at, null: false
      t.index :key, unique: true
    end

    create_table :active_storage_attachments do |t|
      t.string :name, null: false
      t.references :record, null: false, polymorphic: true, index: false
      t.references :blob, null: false, foreign_key: { to_table: :active_storage_blobs }
      t.datetime :created_at, null: false
      t.index [ :record_type, :record_id, :name, :blob_id ],
        name: :index_active_storage_attachments_uniqueness,
        unique: true
    end

    create_table :active_storage_variant_records do |t|
      t.references :blob, null: false, foreign_key: { to_table: :active_storage_blobs }
      t.string :variation_digest, null: false
      t.index [ :blob_id, :variation_digest ], name: :index_active_storage_variant_records_uniqueness, unique: true
    end

    create_table :search_documents do |t|
      t.references :searchable, polymorphic: true, null: false, index: { unique: true }
      t.string :owner_type
      t.bigint :owner_id
      t.string :resource_slug, null: false
      t.string :resource_type, null: false
      t.string :title, null: false
      t.text :content, default: "", null: false
      t.string :api_path, null: false
      t.jsonb :metadata, default: {}, null: false
      t.datetime :resource_updated_at, null: false
      t.virtual :search_vector,
        type: :tsvector,
        as: "to_tsvector('simple'::regconfig, (((((COALESCE(resource_slug, ''::character varying))::text || ' '::text) || (COALESCE(title, ''::character varying))::text) || ' '::text) || COALESCE(content, ''::text)))",
        stored: true
      t.timestamps
      t.index [ :owner_type, :owner_id ]
      t.index :resource_slug, unique: true
      t.index :resource_type
      t.index :metadata, using: :gin
      t.index :search_vector, using: :gin
      t.index :resource_slug, using: :gin, opclass: :gin_trgm_ops, name: :index_search_documents_on_resource_slug_trgm
      t.index :title, using: :gin, opclass: :gin_trgm_ops, name: :index_search_documents_on_title_trgm
      t.index :content, using: :gin, opclass: :gin_trgm_ops, name: :index_search_documents_on_content_trgm
    end

    create_table :chat_conversations do |t|
      t.string :kind, null: false
      t.string :direct_key
      t.references :organization, foreign_key: true
      t.bigint :parent_message_id
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.datetime :last_message_at
      t.timestamps
      t.index :direct_key, unique: true, where: "direct_key IS NOT NULL"
      t.index :kind
      t.index [ :organization_id, :kind ]
      t.index :parent_message_id, unique: true, where: "parent_message_id IS NOT NULL"
    end

    create_table :chat_conversation_participants do |t|
      t.references :chat_conversation, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
      t.index [ :chat_conversation_id, :user_id ], unique: true, name: "index_chat_participants_on_conversation_and_user"
    end

    create_table :chat_channels do |t|
      t.references :organization, null: false, foreign_key: { on_delete: :cascade }
      t.references :chat_conversation, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.text :description
      t.timestamps
      t.index :chat_conversation_id, unique: true
      t.index "organization_id, lower((name)::text)",
        name: "index_chat_channels_on_organization_and_lower_name",
        unique: true
    end

    create_table :chat_messages do |t|
      t.references :chat_conversation, null: false, foreign_key: { on_delete: :cascade }
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false
      t.timestamps
      t.index [ :chat_conversation_id, :id ]
    end

    create_table :pghero_query_stats do |t|
      t.text :database
      t.text :user
      t.text :query
      t.bigint :query_hash
      t.float :total_time
      t.bigint :calls
      t.datetime :captured_at
      t.index [ :database, :captured_at ]
    end

    create_table :pghero_space_stats do |t|
      t.text :database
      t.text :schema
      t.text :relation
      t.bigint :size
      t.datetime :captured_at
      t.index [ :database, :captured_at ]
    end

    add_foreign_key :chat_conversations, :chat_messages, column: :parent_message_id, on_delete: :cascade
  end
end

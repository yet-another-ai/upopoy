# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_09_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_stat_statements"
  enable_extension "pg_trgm"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
    t.index ["blob_id"], name: "index_active_storage_variant_records_on_blob_id"
  end

  create_table "application_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "email_login_enabled", default: true, null: false
    t.boolean "registration_enabled", default: true, null: false
    t.integer "singleton_guard", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["singleton_guard"], name: "index_application_settings_on_singleton_guard", unique: true
  end

  create_table "chat_channels", force: :cascade do |t|
    t.bigint "chat_conversation_id", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.text "description"
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.datetime "updated_at", null: false
    t.index "organization_id, lower((name)::text)", name: "index_chat_channels_on_organization_and_lower_name", unique: true
    t.index ["chat_conversation_id"], name: "index_chat_channels_on_chat_conversation_id", unique: true
    t.index ["created_by_id"], name: "index_chat_channels_on_created_by_id"
    t.index ["organization_id"], name: "index_chat_channels_on_organization_id"
  end

  create_table "chat_conversation_participants", force: :cascade do |t|
    t.bigint "chat_conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["chat_conversation_id", "user_id"], name: "index_chat_participants_on_conversation_and_user", unique: true
    t.index ["user_id"], name: "index_chat_conversation_participants_on_user_id"
  end

  create_table "chat_conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.string "direct_key"
    t.string "kind", null: false
    t.datetime "last_message_at"
    t.bigint "organization_id"
    t.bigint "parent_message_id"
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_chat_conversations_on_created_by_id"
    t.index ["direct_key"], name: "index_chat_conversations_on_direct_key", unique: true, where: "(direct_key IS NOT NULL)"
    t.index ["kind"], name: "index_chat_conversations_on_kind"
    t.index ["organization_id", "kind"], name: "index_chat_conversations_on_organization_id_and_kind"
    t.index ["organization_id"], name: "index_chat_conversations_on_organization_id"
    t.index ["parent_message_id"], name: "index_chat_conversations_on_parent_message_id", unique: true, where: "(parent_message_id IS NOT NULL)"
  end

  create_table "chat_messages", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.text "body", null: false
    t.bigint "chat_conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_chat_messages_on_author_id"
    t.index ["chat_conversation_id", "id"], name: "index_chat_messages_on_chat_conversation_id_and_id"
    t.index ["chat_conversation_id"], name: "index_chat_messages_on_chat_conversation_id"
  end

  create_table "drive_item_versions", force: :cascade do |t|
    t.bigint "byte_size"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.bigint "drive_item_id", null: false
    t.string "name", null: false
    t.text "text_content_cache", default: "", null: false
    t.datetime "updated_at", null: false
    t.integer "version_number", null: false
    t.index ["drive_item_id", "version_number"], name: "index_drive_item_versions_on_drive_item_id_and_version_number", unique: true
    t.index ["drive_item_id"], name: "index_drive_item_versions_on_drive_item_id"
  end

  create_table "drive_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "kind", null: false
    t.string "name", null: false
    t.bigint "parent_id"
    t.bigint "project_id", null: false
    t.text "text_content_cache", default: "", null: false
    t.datetime "updated_at", null: false
    t.index "project_id, lower((name)::text)", name: "index_drive_items_on_project_root_name", unique: true, where: "((parent_id IS NULL) AND (deleted_at IS NULL))"
    t.index "project_id, parent_id, lower((name)::text)", name: "index_drive_items_on_project_parent_name", unique: true, where: "((parent_id IS NOT NULL) AND (deleted_at IS NULL))"
    t.index ["deleted_at"], name: "index_drive_items_on_deleted_at"
    t.index ["parent_id"], name: "index_drive_items_on_parent_id"
    t.index ["project_id", "kind"], name: "index_drive_items_on_project_id_and_kind"
    t.index ["project_id"], name: "index_drive_items_on_project_id"
  end

  create_table "iterations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deadline"
    t.boolean "inbox", default: false, null: false
    t.string "name", null: false
    t.bigint "project_id", null: false
    t.datetime "starts_at"
    t.datetime "updated_at", null: false
    t.index ["project_id", "inbox"], name: "index_iterations_on_project_id_and_inbox", unique: true, where: "(inbox = true)"
    t.index ["project_id"], name: "index_iterations_on_project_id"
  end

  create_table "oauth_identities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["provider", "uid"], name: "index_oauth_identities_on_provider_and_uid", unique: true
    t.index ["user_id", "provider"], name: "index_oauth_identities_on_user_id_and_provider", unique: true
    t.index ["user_id"], name: "index_oauth_identities_on_user_id"
  end

  create_table "organization_memberships", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.bigint "organization_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["organization_id", "admin"], name: "index_organization_memberships_on_organization_id_and_admin"
    t.index ["organization_id", "user_id"], name: "index_organization_memberships_on_organization_id_and_user_id", unique: true
    t.index ["organization_id"], name: "index_organization_memberships_on_organization_id"
    t.index ["user_id"], name: "index_organization_memberships_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "pghero_query_stats", force: :cascade do |t|
    t.bigint "calls"
    t.datetime "captured_at"
    t.text "database"
    t.text "query"
    t.bigint "query_hash"
    t.float "total_time"
    t.text "user"
    t.index ["database", "captured_at"], name: "index_pghero_query_stats_on_database_and_captured_at"
  end

  create_table "pghero_space_stats", force: :cascade do |t|
    t.datetime "captured_at"
    t.text "database"
    t.text "relation"
    t.text "schema"
    t.bigint "size"
    t.index ["database", "captured_at"], name: "index_pghero_space_stats_on_database_and_captured_at"
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.bigint "owner_id", null: false
    t.string "owner_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["owner_type", "owner_id"], name: "index_projects_on_owner_type_and_owner_id"
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "search_documents", force: :cascade do |t|
    t.string "api_path", null: false
    t.text "content", default: "", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "owner_id"
    t.string "owner_type"
    t.string "resource_slug", null: false
    t.string "resource_type", null: false
    t.datetime "resource_updated_at", null: false
    t.virtual "search_vector", type: :tsvector, as: "to_tsvector('simple'::regconfig, (((((COALESCE(resource_slug, ''::character varying))::text || ' '::text) || (COALESCE(title, ''::character varying))::text) || ' '::text) || COALESCE(content, ''::text)))", stored: true
    t.bigint "searchable_id", null: false
    t.string "searchable_type", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["content"], name: "index_search_documents_on_content_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["metadata"], name: "index_search_documents_on_metadata", using: :gin
    t.index ["owner_type", "owner_id"], name: "index_search_documents_on_owner_type_and_owner_id"
    t.index ["resource_slug"], name: "index_search_documents_on_resource_slug", unique: true
    t.index ["resource_slug"], name: "index_search_documents_on_resource_slug_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["resource_type"], name: "index_search_documents_on_resource_type"
    t.index ["search_vector"], name: "index_search_documents_on_search_vector", using: :gin
    t.index ["searchable_type", "searchable_id"], name: "index_search_documents_on_searchable", unique: true
    t.index ["title"], name: "index_search_documents_on_title_trgm", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "task_developers", id: false, force: :cascade do |t|
    t.bigint "task_id", null: false
    t.bigint "user_id", null: false
    t.index ["task_id", "user_id"], name: "index_task_developers_on_task_id_and_user_id", unique: true
    t.index ["task_id"], name: "index_task_developers_on_task_id"
    t.index ["user_id"], name: "index_task_developers_on_user_id"
  end

  create_table "task_reviewers", id: false, force: :cascade do |t|
    t.bigint "task_id", null: false
    t.bigint "user_id", null: false
    t.index ["task_id", "user_id"], name: "index_task_reviewers_on_task_id_and_user_id", unique: true
    t.index ["task_id"], name: "index_task_reviewers_on_task_id"
    t.index ["user_id"], name: "index_task_reviewers_on_user_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deadline"
    t.text "description"
    t.integer "estimated_minutes"
    t.bigint "iteration_id"
    t.integer "position", default: 0, null: false
    t.string "priority", default: "medium", null: false
    t.bigint "project_id", null: false
    t.string "status", default: "todo", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["iteration_id"], name: "index_tasks_on_iteration_id"
    t.index ["project_id", "status", "position"], name: "index_tasks_on_project_id_and_status_and_position"
    t.index ["project_id"], name: "index_tasks_on_project_id"
  end

  create_table "users", force: :cascade do |t|
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "jti", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.json "skills", default: [], null: false
    t.boolean "system_admin", default: false, null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "chat_channels", "chat_conversations", on_delete: :cascade
  add_foreign_key "chat_channels", "organizations", on_delete: :cascade
  add_foreign_key "chat_channels", "users", column: "created_by_id"
  add_foreign_key "chat_conversation_participants", "chat_conversations", on_delete: :cascade
  add_foreign_key "chat_conversation_participants", "users", on_delete: :cascade
  add_foreign_key "chat_conversations", "chat_messages", column: "parent_message_id", on_delete: :cascade
  add_foreign_key "chat_conversations", "organizations"
  add_foreign_key "chat_conversations", "users", column: "created_by_id"
  add_foreign_key "chat_messages", "chat_conversations", on_delete: :cascade
  add_foreign_key "chat_messages", "users", column: "author_id"
  add_foreign_key "drive_item_versions", "drive_items", on_delete: :cascade
  add_foreign_key "drive_items", "drive_items", column: "parent_id", on_delete: :cascade
  add_foreign_key "drive_items", "projects", on_delete: :cascade
  add_foreign_key "iterations", "projects", on_delete: :cascade
  add_foreign_key "oauth_identities", "users"
  add_foreign_key "organization_memberships", "organizations", on_delete: :cascade
  add_foreign_key "organization_memberships", "users", on_delete: :cascade
  add_foreign_key "projects", "users"
  add_foreign_key "task_developers", "tasks", on_delete: :cascade
  add_foreign_key "task_developers", "users", on_delete: :cascade
  add_foreign_key "task_reviewers", "tasks", on_delete: :cascade
  add_foreign_key "task_reviewers", "users", on_delete: :cascade
  add_foreign_key "tasks", "iterations", on_delete: :nullify
  add_foreign_key "tasks", "projects"
end

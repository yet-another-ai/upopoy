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

ActiveRecord::Schema[8.1].define(version: 2026_07_08_031000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "application_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "email_login_enabled", default: true, null: false
    t.boolean "registration_enabled", default: true, null: false
    t.integer "singleton_guard", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["singleton_guard"], name: "index_application_settings_on_singleton_guard", unique: true
  end

  create_table "group_hierarchies", force: :cascade do |t|
    t.bigint "ancestor_group_id", null: false
    t.datetime "created_at", null: false
    t.integer "depth", null: false
    t.bigint "descendant_group_id", null: false
    t.datetime "updated_at", null: false
    t.index ["ancestor_group_id", "descendant_group_id"], name: "index_group_hierarchies_on_ancestor_and_descendant", unique: true
    t.index ["descendant_group_id"], name: "index_group_hierarchies_on_descendant_group_id"
  end

  create_table "group_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "group_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["group_id", "user_id"], name: "index_group_memberships_on_group_id_and_user_id", unique: true
    t.index ["group_id"], name: "index_group_memberships_on_group_id"
    t.index ["user_id"], name: "index_group_memberships_on_user_id"
  end

  create_table "groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.bigint "parent_group_id"
    t.datetime "updated_at", null: false
    t.index ["parent_group_id"], name: "index_groups_on_parent_group_id"
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

  create_table "pghero_query_stats", force: :cascade do |t|
    t.bigint "calls"
    t.datetime "captured_at", precision: nil
    t.text "database"
    t.text "query"
    t.bigint "query_hash"
    t.float "total_time"
    t.text "user"
    t.index ["database", "captured_at"], name: "index_pghero_query_stats_on_database_and_captured_at"
  end

  create_table "pghero_space_stats", force: :cascade do |t|
    t.datetime "captured_at", precision: nil
    t.text "database"
    t.text "relation"
    t.text "schema"
    t.bigint "size"
    t.index ["database", "captured_at"], name: "index_pghero_space_stats_on_database_and_captured_at"
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "group_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["group_id"], name: "index_projects_on_group_id"
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "search_documents", force: :cascade do |t|
    t.string "api_path", null: false
    t.text "content", default: "", null: false
    t.datetime "created_at", null: false
    t.bigint "group_id"
    t.jsonb "metadata", default: {}, null: false
    t.string "resource_slug", null: false
    t.string "resource_type", null: false
    t.datetime "resource_updated_at", null: false
    t.virtual "search_vector", type: :tsvector, as: "to_tsvector('simple'::regconfig, (((((COALESCE(resource_slug, ''::character varying))::text || ' '::text) || (COALESCE(title, ''::character varying))::text) || ' '::text) || COALESCE(content, ''::text)))", stored: true
    t.bigint "searchable_id", null: false
    t.string "searchable_type", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["content"], name: "index_search_documents_on_content_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["group_id"], name: "index_search_documents_on_group_id"
    t.index ["metadata"], name: "index_search_documents_on_metadata", using: :gin
    t.index ["resource_slug"], name: "index_search_documents_on_resource_slug", unique: true
    t.index ["resource_slug"], name: "index_search_documents_on_resource_slug_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["resource_type"], name: "index_search_documents_on_resource_type"
    t.index ["search_vector"], name: "index_search_documents_on_search_vector", using: :gin
    t.index ["searchable_type", "searchable_id"], name: "index_search_documents_on_searchable_type_and_searchable_id", unique: true
    t.index ["title"], name: "index_search_documents_on_title_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["user_id"], name: "index_search_documents_on_user_id"
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
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "group_hierarchies", "groups", column: "ancestor_group_id", on_delete: :cascade
  add_foreign_key "group_hierarchies", "groups", column: "descendant_group_id", on_delete: :cascade
  add_foreign_key "group_memberships", "groups", on_delete: :cascade
  add_foreign_key "group_memberships", "users", on_delete: :cascade
  add_foreign_key "groups", "groups", column: "parent_group_id", on_delete: :nullify
  add_foreign_key "iterations", "projects", on_delete: :cascade
  add_foreign_key "oauth_identities", "users"
  add_foreign_key "projects", "groups"
  add_foreign_key "projects", "users"
  add_foreign_key "search_documents", "groups"
  add_foreign_key "search_documents", "users"
  add_foreign_key "tasks", "iterations", on_delete: :nullify
  add_foreign_key "tasks", "projects"
end

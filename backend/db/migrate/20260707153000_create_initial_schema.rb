class CreateInitialSchema < ActiveRecord::Migration[8.1]
  def up
    enable_extension "pg_trgm"

    create_users
    create_application_settings
    create_groups
    create_group_memberships
    create_oauth_identities
    create_projects
    create_tasks
    create_search_documents
    add_foreign_keys
  end

  def down
    drop_table :search_documents
    drop_table :tasks
    drop_table :projects
    drop_table :oauth_identities
    drop_table :group_memberships
    drop_table :groups
    drop_table :application_settings
    drop_table :users
  end

  private

  def create_users
    create_table :users do |t|
      t.text :bio
      t.string :display_name
      t.string :email, default: "", null: false
      t.string :encrypted_password, default: "", null: false
      t.string :jti, null: false
      t.datetime :remember_created_at
      t.datetime :reset_password_sent_at
      t.string :reset_password_token
      t.string :title

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :jti, unique: true
    add_index :users, :reset_password_token, unique: true
  end

  def create_application_settings
    create_table :application_settings do |t|
      t.boolean :email_login_enabled, default: true, null: false
      t.boolean :registration_enabled, default: true, null: false
      t.integer :singleton_guard, default: 0, null: false

      t.timestamps
    end

    add_index :application_settings, :singleton_guard, unique: true
  end

  def create_groups
    create_table :groups do |t|
      t.text :description
      t.string :name, null: false
      t.bigint :parent_group_id

      t.timestamps
    end

    add_index :groups, :parent_group_id
  end

  def create_group_memberships
    create_table :group_memberships do |t|
      t.bigint :group_id, null: false
      t.bigint :user_id, null: false

      t.timestamps
    end

    add_index :group_memberships, [ :group_id, :user_id ], unique: true
    add_index :group_memberships, :group_id
    add_index :group_memberships, :user_id
  end

  def create_oauth_identities
    create_table :oauth_identities do |t|
      t.string :provider, null: false
      t.string :uid, null: false
      t.bigint :user_id, null: false

      t.timestamps
    end

    add_index :oauth_identities, [ :provider, :uid ], unique: true
    add_index :oauth_identities, [ :user_id, :provider ], unique: true
    add_index :oauth_identities, :user_id
  end

  def create_projects
    create_table :projects do |t|
      t.text :description
      t.string :name, null: false
      t.bigint :user_id, null: false

      t.timestamps
    end

    add_index :projects, :user_id
  end

  def create_tasks
    create_table :tasks do |t|
      t.datetime :deadline
      t.text :description
      t.integer :estimated_minutes
      t.integer :position, default: 0, null: false
      t.string :priority, default: "medium", null: false
      t.bigint :project_id, null: false
      t.string :status, default: "todo", null: false
      t.string :title, null: false

      t.timestamps
    end

    add_index :tasks, [ :project_id, :status, :position ]
    add_index :tasks, :project_id
  end

  def create_search_documents
    create_table :search_documents do |t|
      t.string :api_path, null: false
      t.text :content, default: "", null: false
      t.jsonb :metadata, default: {}, null: false
      t.string :resource_slug, null: false
      t.string :resource_type, null: false
      t.datetime :resource_updated_at, null: false
      t.bigint :searchable_id, null: false
      t.string :searchable_type, null: false
      t.string :title, null: false
      t.bigint :user_id

      t.timestamps
    end

    add_index :search_documents, :content, name: "index_search_documents_on_content_trgm",
      opclass: :gin_trgm_ops, using: :gin
    add_index :search_documents, :metadata, using: :gin
    add_index :search_documents, :resource_slug, unique: true
    add_index :search_documents, :resource_slug, name: "index_search_documents_on_resource_slug_trgm",
      opclass: :gin_trgm_ops, using: :gin
    add_index :search_documents, :resource_type
    add_index :search_documents, [ :searchable_type, :searchable_id ], unique: true
    add_index :search_documents, :title, name: "index_search_documents_on_title_trgm",
      opclass: :gin_trgm_ops, using: :gin
    add_index :search_documents, :user_id

    add_search_vector
  end

  def add_search_vector
    execute <<~SQL
      ALTER TABLE search_documents
      ADD COLUMN search_vector tsvector GENERATED ALWAYS AS (
        to_tsvector(
          'simple',
          coalesce(resource_slug, '') || ' ' ||
          coalesce(title, '') || ' ' ||
          coalesce(content, '')
        )
      ) STORED
    SQL

    add_index :search_documents, :search_vector, using: :gin
  end

  def add_foreign_keys
    add_foreign_key :group_memberships, :groups, on_delete: :cascade
    add_foreign_key :group_memberships, :users, on_delete: :cascade
    add_foreign_key :groups, :groups, column: :parent_group_id, on_delete: :nullify
    add_foreign_key :oauth_identities, :users
    add_foreign_key :projects, :users
    add_foreign_key :search_documents, :users
    add_foreign_key :tasks, :projects
  end
end

class SearchDocument < ApplicationRecord
  RESOURCE_TYPES = {
    "project" => "Project",
    "task" => "Task",
    "user" => "User",
    "group" => "Group"
  }.freeze

  belongs_to :searchable, polymorphic: true
  belongs_to :user, optional: true

  validates :resource_slug, presence: true, uniqueness: true
  validates :resource_type, presence: true, inclusion: { in: RESOURCE_TYPES.keys }
  validates :searchable_type, presence: true
  validates :searchable_id, presence: true
  validates :title, presence: true
  validates :api_path, presence: true
  validates :resource_updated_at, presence: true

  scope :visible_to, lambda { |user|
    where(user_id: nil).or(where(user_id: user.id))
  }

  scope :of_resource_type, ->(resource_type) { where(resource_type:) if resource_type.present? }

  def self.upsert_for(resource)
    document = find_or_initialize_by(searchable: resource)
    document.assign_attributes(
      user_id: resource.search_owner_user_id,
      resource_slug: resource.resource_slug,
      resource_type: resource.class.search_resource_type,
      title: resource.search_title,
      content: resource.search_content.to_s,
      api_path: resource.search_api_path,
      metadata: resource.search_metadata,
      resource_updated_at: resource.updated_at
    )
    document.save!
    document
  end

  def self.search(query:, user:, resource_type: nil, limit: 20)
    normalized_query = query.to_s.strip
    return none if normalized_query.blank?

    scoped = visible_to(user).of_resource_type(resource_type)
    scoped.where(search_predicate, query: normalized_query, like_query: "%#{sanitize_sql_like(normalized_query)}%")
      .order(search_order(normalized_query))
      .limit(limit)
  end

  def self.search_predicate
    <<~SQL.squish
      resource_slug = :query
      OR search_vector @@ plainto_tsquery('simple', :query)
      OR resource_slug ILIKE :like_query
      OR title ILIKE :like_query
      OR content ILIKE :like_query
      OR similarity(resource_slug, :query) > 0.2
      OR similarity(title, :query) > 0.2
      OR similarity(content, :query) > 0.2
    SQL
  end

  def self.search_order(query)
    sanitized_sql = sanitize_sql_array(
      [
        <<~SQL.squish,
          CASE WHEN resource_slug = ? THEN 0 ELSE 1 END,
          ts_rank_cd(search_vector, plainto_tsquery('simple', ?)) DESC,
          GREATEST(similarity(resource_slug, ?), similarity(title, ?), similarity(content, ?)) DESC,
          resource_updated_at DESC
        SQL
        query,
        query,
        query,
        query,
        query
      ]
    )

    Arel.sql(sanitized_sql)
  end
end

class DriveItem < ApplicationRecord
  include SearchableResource
  include SoftDeletable

  KINDS = %w[ folder file ].freeze
  MARKDOWN_EXTENSIONS = %w[ .md .markdown ].freeze

  search_index_attributes :name, :text_content_cache, :project_id

  belongs_to :project
  belongs_to :parent, class_name: "DriveItem", optional: true, inverse_of: :children
  has_many :children, class_name: "DriveItem", foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent
  has_many :versions, class_name: "DriveItemVersion", dependent: :destroy
  has_one_attached :file

  before_validation :normalize_name

  validates :kind, presence: true, inclusion: { in: KINDS }
  validates :name, presence: true
  validates :name,
    uniqueness: {
      scope: [ :project_id, :parent_id ],
      case_sensitive: false,
      conditions: -> { where(deleted_at: nil) }
    }
  validate :parent_belongs_to_project
  validate :parent_is_folder
  validate :parent_is_not_self_or_descendant
  validate :file_attachment_matches_kind

  scope :ordered, -> {
    order(
      Arel.sql("CASE WHEN drive_items.kind = 'folder' THEN 0 ELSE 1 END"),
      Arel.sql("LOWER(drive_items.name) ASC"),
      :id
    )
  }

  def folder?
    kind == "folder"
  end

  def file?
    kind == "file"
  end

  def markdown?
    file? && MARKDOWN_EXTENSIONS.any? { |extension| name.downcase.end_with?(extension) }
  end

  def content_type
    file.blob&.content_type if file.attached?
  end

  def byte_size
    file.blob&.byte_size if file.attached?
  end

  def markdown_content
    return "" unless markdown? && file.attached?

    file.download.force_encoding(Encoding::UTF_8).scrub
  end

  def attach_markdown_content!(content)
    normalized_content = content.to_s
    file.attach(
      io: StringIO.new(normalized_content),
      filename: name,
      content_type: "text/markdown"
    )
    self.text_content_cache = normalized_content
  end

  def record_version!
    return unless file? && file.attached?

    version = versions.build(
      version_number: next_version_number,
      name: name,
      content_type: content_type,
      byte_size: byte_size,
      text_content_cache: text_content_cache
    )
    version.file.attach(file.blob)
    version.save!
    version
  end

  def latest_version_number
    versions.maximum(:version_number)
  end

  def restore_version!(version)
    raise ActiveRecord::RecordNotFound unless version.drive_item_id == id

    file.attach(version.file.blob)
    self.text_content_cache = version.text_content_cache
    save!
    record_version!
  end

  def soft_delete!(timestamp: Time.current)
    transaction do
      children.find_each { |child| child.soft_delete!(timestamp:) }
      super
    end
  end

  def search_title
    name
  end

  def search_content
    text_content_cache
  end

  def search_owner
    project&.owner
  end

  def search_metadata
    {
      project_id: project_id,
      owner_type: project&.owner_type,
      owner_id: project&.owner_id,
      parent_id: parent_id,
      kind: kind,
      markdown: markdown?,
      deleted: deleted?
    }
  end

  def search_api_path
    "/api/v1/drive_items/#{id}"
  end

  private

  def normalize_name
    self.name = name.to_s.strip.presence
  end

  def parent_belongs_to_project
    return if parent.blank? || parent.project_id == project_id

    errors.add(:parent, "must belong to the same project")
  end

  def parent_is_folder
    return if parent.blank? || parent.folder?

    errors.add(:parent, "must be a folder")
  end

  def parent_is_not_self_or_descendant
    return if parent.blank? || id.blank?

    ancestor = parent
    while ancestor
      if ancestor.id == id
        errors.add(:parent, "cannot be itself or one of its descendants")
        break
      end

      ancestor = ancestor.parent
    end
  end

  def file_attachment_matches_kind
    errors.add(:file, "must be attached") if file? && !file.attached?
    errors.add(:file, "must be blank for folders") if folder? && file.attached?
  end

  def next_version_number
    versions.maximum(:version_number).to_i + 1
  end
end

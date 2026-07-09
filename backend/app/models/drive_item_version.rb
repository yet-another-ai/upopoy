class DriveItemVersion < ApplicationRecord
  belongs_to :drive_item
  has_one_attached :file

  validates :version_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :name, presence: true
  validates :version_number, uniqueness: { scope: :drive_item_id }
  validate :file_attached

  scope :ordered, -> { order(version_number: :desc) }

  def markdown?
    DriveItem::MARKDOWN_EXTENSIONS.any? { |extension| name.downcase.end_with?(extension) }
  end

  def markdown_content
    return "" unless markdown? && file.attached?

    file.download.force_encoding(Encoding::UTF_8).scrub
  end

  private

  def file_attached
    errors.add(:file, "must be attached") unless file.attached?
  end
end

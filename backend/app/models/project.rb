class Project < ApplicationRecord
  include SearchableResource

  OWNER_TYPES = %w[User Organization].freeze

  search_index_attributes :name, :description, :user_id, :owner_type, :owner_id

  belongs_to :user
  belongs_to :owner, polymorphic: true
  has_many :iterations, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :drive_items, dependent: :destroy

  after_create :ensure_inbox_iteration

  validates :name, presence: true
  validates :owner_type, inclusion: { in: OWNER_TYPES }
  validates :owner, presence: true

  def inbox_iteration
    iterations.find_or_create_by!(inbox: true) do |iteration|
      iteration.name = "Inbox"
    end
  end

  def search_title
    name
  end

  def search_content
    description
  end

  def search_owner_user_id
    owner_id if owner_type == "User"
  end

  def search_owner
    owner
  end

  def search_metadata
    { owner_type:, owner_id: }
  end

  def search_api_path
    "/api/v1/projects/#{id}"
  end

  private

  def ensure_inbox_iteration
    inbox_iteration
  end
end

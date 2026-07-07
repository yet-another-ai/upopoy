class Project < ApplicationRecord
  include SearchableResource

  search_index_attributes :name, :description, :user_id, :group_id

  belongs_to :user
  belongs_to :group
  has_many :iterations, dependent: :destroy
  has_many :tasks, dependent: :destroy

  after_create :ensure_inbox_iteration

  validates :name, presence: true

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
    nil
  end

  def search_owner_group_id
    group_id
  end

  def search_metadata
    { group_id: group_id }
  end

  def search_api_path
    "/api/v1/projects/#{id}"
  end

  private

  def ensure_inbox_iteration
    inbox_iteration
  end
end

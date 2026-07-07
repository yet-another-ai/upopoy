class Project < ApplicationRecord
  include SearchableResource

  search_index_attributes :name, :description, :user_id, :group_id

  belongs_to :user
  belongs_to :group
  has_many :tasks, dependent: :destroy

  validates :name, presence: true

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
end

class Organization < ApplicationRecord
  include SearchableResource

  attr_accessor :admin_user_ids

  search_index_attributes :name, :description

  has_many :organization_memberships, dependent: :destroy
  has_many :users, through: :organization_memberships
  has_many :projects, as: :owner, dependent: :destroy
  has_many :chat_conversations, dependent: :destroy
  has_many :chat_channels, dependent: :destroy

  validates :name, presence: true

  def search_title
    name
  end

  def search_content
    description
  end

  def search_owner
    self
  end

  def search_metadata
    {}
  end

  def search_api_path
    "/api/v1/organizations/#{id}"
  end
end

class Group < ApplicationRecord
  include SearchableResource

  attr_accessor :admin_user_ids

  search_index_attributes :name, :description

  belongs_to :parent_group,
             class_name: "Group",
             optional: true,
             inverse_of: :groups

  has_many :groups,
           class_name: "Group",
           foreign_key: :parent_group_id,
           inverse_of: :parent_group,
           dependent: :nullify
  has_many :group_memberships, dependent: :destroy
  has_many :users, through: :group_memberships
  has_many :projects, dependent: :destroy
  has_many :ancestor_group_hierarchies,
           class_name: "GroupHierarchy",
           foreign_key: :descendant_group_id,
           dependent: :destroy,
           inverse_of: :descendant_group
  has_many :ancestors, through: :ancestor_group_hierarchies, source: :ancestor_group
  has_many :descendant_group_hierarchies,
           class_name: "GroupHierarchy",
           foreign_key: :ancestor_group_id,
           dependent: :destroy,
           inverse_of: :ancestor_group
  has_many :descendants, through: :descendant_group_hierarchies, source: :descendant_group

  validates :name, presence: true
  validate :parent_group_cannot_be_self
  validate :parent_group_cannot_create_cycle

  after_create :rebuild_group_hierarchies
  after_update :rebuild_group_hierarchies, if: :saved_change_to_parent_group_id?
  after_destroy :rebuild_group_hierarchies

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
    id
  end

  def search_metadata
    {}
  end

  def search_api_path
    "/api/v1/groups/#{id}"
  end

  private

  def parent_group_cannot_be_self
    return if parent_group_id.blank? || parent_group_id != id

    errors.add(:parent_group, "cannot be itself")
  end

  def parent_group_cannot_create_cycle
    return if parent_group_id.blank? || id.blank?

    ancestor = parent_group
    while ancestor
      if ancestor.id == id
        errors.add(:parent_group, "cannot be a child group")
        break
      end

      ancestor = ancestor.parent_group
    end
  end

  def rebuild_group_hierarchies
    GroupHierarchy.rebuild!
  end
end

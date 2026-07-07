class Group < ApplicationRecord
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

  validates :name, presence: true
  validate :parent_group_cannot_be_self
  validate :parent_group_cannot_create_cycle

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
end

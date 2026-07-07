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

  private

  def parent_group_cannot_be_self
    return if parent_group_id.blank? || parent_group_id != id

    errors.add(:parent_group, "cannot be itself")
  end
end

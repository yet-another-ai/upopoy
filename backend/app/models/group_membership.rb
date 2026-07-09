class GroupMembership < ApplicationRecord
  belongs_to :group
  belongs_to :user

  validates :user_id, uniqueness: { scope: :group_id }
  validate :group_must_keep_admin, if: :removing_admin?

  before_destroy :ensure_group_keeps_admin

  private

  def removing_admin?
    persisted? && will_save_change_to_admin? && admin == false
  end

  def group_must_keep_admin
    return if group_has_another_admin?

    errors.add(:admin, "must have at least one group admin")
  end

  def ensure_group_keeps_admin
    return if destroyed_by_association.present? || group_has_another_admin?

    errors.add(:admin, "must have at least one group admin")
    throw :abort
  end

  def group_has_another_admin?
    group.group_memberships.where(admin: true).where.not(id:).exists?
  end
end

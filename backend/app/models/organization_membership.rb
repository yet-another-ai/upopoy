class OrganizationMembership < ApplicationRecord
  belongs_to :organization
  belongs_to :user

  validates :user_id, uniqueness: { scope: :organization_id }
  validate :organization_must_keep_admin, if: :removing_admin?

  before_destroy :ensure_organization_keeps_admin

  scope :accessible_organization_ids_for, ->(user) { where(user_id: user.id).select(:organization_id) }
  scope :adminable_organization_ids_for, ->(user) { where(user_id: user.id, admin: true).select(:organization_id) }

  private

  def removing_admin?
    persisted? && will_save_change_to_admin? && admin == false
  end

  def organization_must_keep_admin
    return if organization_has_another_admin?

    errors.add(:admin, "must have at least one organization admin")
  end

  def ensure_organization_keeps_admin
    return if destroyed_by_association.present? || organization_has_another_admin?

    errors.add(:admin, "must have at least one organization admin")
    throw :abort
  end

  def organization_has_another_admin?
    organization.organization_memberships.where(admin: true).where.not(id:).exists?
  end
end

class User < ApplicationRecord
  include SearchableResource
  include Devise::JWT::RevocationStrategies::JTIMatcher

  SKILL_LEVELS = %w[learning working advanced expert].freeze

  search_index_attributes :email, :display_name, :title, :bio, :skills

  before_validation :normalize_skills
  validate :skills_are_well_formed

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable,
         :jwt_authenticatable,
         omniauth_providers: Rails.application.config.x.auth_provider_names,
         jwt_revocation_strategy: self

  has_many :projects, dependent: :destroy
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships
  has_many :oauth_identities, dependent: :destroy

  def accessible_group_ids
    return Group.ids if system_admin?

    @accessible_group_ids ||= GroupHierarchy.accessible_group_ids_for(self).pluck(:descendant_group_id)
  end

  def can_access_group?(group_id)
    return group_id.present? if system_admin?

    group_id.present? && accessible_group_ids.include?(group_id)
  end

  def adminable_group_ids
    return Group.ids if system_admin?

    @adminable_group_ids ||= GroupHierarchy.adminable_group_ids_for(self).pluck(:descendant_group_id)
  end

  def can_admin_group?(group_id)
    return group_id.present? if system_admin?

    group_id.present? && adminable_group_ids.include?(group_id)
  end

  def self.from_omniauth(auth)
    identity = OauthIdentity.find_by(provider: auth.provider, uid: auth.uid)
    return identity.user if identity

    email = auth.info&.email.presence || "#{auth.provider}-#{auth.uid}@oauth.upopoy.local"
    user = find_or_initialize_by(email:)
    user.password = Devise.friendly_token.first(32) if user.encrypted_password.blank?
    user.save!

    user.oauth_identities.create!(provider: auth.provider, uid: auth.uid)
    user
  end

  def search_title
    display_name.presence || email
  end

  def search_content
    [
      email,
      title,
      bio,
      skill_search_content
    ].compact.join("\n")
  end

  def search_owner_user_id
    nil
  end

  def search_metadata
    { skills: }
  end

  def search_api_path
    "/api/v1/users/#{id}"
  end

  private

  def normalize_skills
    self.skills = Array(skills).filter_map do |skill|
      next unless skill.respond_to?(:to_h)

      attributes = skill.to_h.stringify_keys
      name = attributes["name"].to_s.strip
      next if name.blank?

      {
        "name" => name,
        "level" => attributes["level"].to_s.presence || "working",
        "note" => attributes["note"].to_s.strip
      }
    end
  end

  def skills_are_well_formed
    errors.add(:skills, "must include no more than 50 items") if skills.size > 50

    skills.each do |skill|
      errors.add(:skills, "name is too long") if skill["name"].to_s.length > 100
      errors.add(:skills, "level is invalid") unless SKILL_LEVELS.include?(skill["level"])
      errors.add(:skills, "note is too long") if skill["note"].to_s.length > 500
    end
  end

  def skill_search_content
    skills.map do |skill|
      [ skill["name"], skill["level"], skill["note"] ].compact_blank.join(" ")
    end.join("\n")
  end
end

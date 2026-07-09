class User < ApplicationRecord
  include SearchableResource
  include Devise::JWT::RevocationStrategies::JTIMatcher

  search_index_attributes :email, :display_name, :title, :bio

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
    group_id.present? && accessible_group_ids.include?(group_id)
  end

  def adminable_group_ids
    return Group.ids if system_admin?

    GroupHierarchy.adminable_group_ids_for(self).pluck(:descendant_group_id)
  end

  def can_admin_group?(group_id)
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
      bio
    ].compact.join("\n")
  end

  def search_owner_user_id
    nil
  end

  def search_metadata
    {}
  end

  def search_api_path
    "/api/v1/users/#{id}"
  end
end

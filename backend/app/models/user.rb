class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

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
end

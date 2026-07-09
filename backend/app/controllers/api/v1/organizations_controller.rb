module Api
  module V1
    class OrganizationsController < BaseController
      before_action :set_organization, only: [ :show, :update, :destroy ]

      def index
        @organizations = policy_scope(Organization).includes(:organization_memberships, :users).order(:name)
      end

      def show
        authorize @organization
      end

      def create
        organization = Organization.new

        persist_organization(organization, :created)
      end

      def update
        persist_organization(@organization)
      end

      def destroy
        authorize @organization
        @organization.destroy!

        head :no_content
      end

      private

      def set_organization
        @organization = policy_scope(Organization).find(params[:id])
      end

      def persist_organization(organization, status = :ok)
        attributes = organization_params
        user_ids = normalize_user_ids(attributes.delete(:user_ids))
        admin_user_ids = normalize_user_ids(attributes.delete(:admin_user_ids))
        user_ids = include_current_user(user_ids) if organization.new_record?
        admin_user_ids = include_current_user(admin_user_ids) if organization.new_record?

        organization.assign_attributes(attributes)
        authorize organization
        return render_invalid_user_ids(:user_ids) unless valid_user_ids?(user_ids)
        return render_invalid_user_ids(:admin_user_ids) unless valid_user_ids?(admin_user_ids)

        Organization.transaction do
          organization.save!
          sync_organization_memberships(organization, user_ids, admin_user_ids)
          ensure_organization_has_admin!(organization)
        end

        @organization = organization.reload
        render :show, status:
      rescue ActiveRecord::RecordInvalid
        render_errors(organization)
      end

      def organization_params
        params.require(:organization).permit(:name, :description, user_ids: [], admin_user_ids: [])
      end

      def normalize_user_ids(raw_user_ids)
        return nil if raw_user_ids.nil?

        raw_user_ids.filter_map do |user_id|
          next if user_id.blank?

          parsed_user_id = Integer(user_id, exception: false)
          return [ nil ] unless parsed_user_id

          parsed_user_id
        end.uniq
      end

      def valid_user_ids?(user_ids)
        return true if user_ids.nil?
        return false if user_ids.any?(&:nil?)

        known_user_ids = User.where(id: user_ids).pluck(:id)
        known_user_ids.sort == user_ids.sort
      end

      def include_current_user(user_ids)
        return [ current_user.id ] if user_ids.nil?

        (user_ids + [ current_user.id ]).uniq
      end

      def sync_organization_memberships(organization, user_ids, admin_user_ids)
        return if user_ids.nil? && admin_user_ids.nil?

        memberships = organization.organization_memberships.index_by(&:user_id)
        final_user_ids = user_ids || memberships.keys
        final_admin_user_ids = admin_user_ids || memberships.values.select(&:admin?).map(&:user_id)
        final_user_ids = (final_user_ids + final_admin_user_ids).uniq

        if final_admin_user_ids.empty?
          organization.errors.add(:admin_user_ids, :blank)
          raise ActiveRecord::RecordInvalid, organization
        end

        final_admin_user_ids.each do |user_id|
          membership = memberships[user_id] || organization.organization_memberships.build(user_id:)
          membership.admin = true
          membership.save!
        end

        (final_user_ids - final_admin_user_ids).each do |user_id|
          membership = memberships[user_id] || organization.organization_memberships.build(user_id:)
          membership.admin = false
          membership.save!
        end

        (memberships.keys - final_user_ids).each do |user_id|
          memberships[user_id].destroy!
        end
      end

      def ensure_organization_has_admin!(organization)
        return if organization.organization_memberships.where(admin: true).exists?

        organization.errors.add(:admin_user_ids, :blank)
        raise ActiveRecord::RecordInvalid, organization
      end

      def render_invalid_user_ids(attribute)
        render "api/v1/errors/show",
          formats: :json,
          locals: { errors: { attribute => [ I18n.t("api.errors.include_unknown_users") ] } },
          status: :unprocessable_entity
      end
    end
  end
end

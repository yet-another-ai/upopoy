module Api
  module V1
    class GroupsController < BaseController
      before_action :set_group, only: [ :show, :update, :destroy ]

      def index
        @groups = policy_scope(Group).includes(:parent_group, :group_memberships, :users).order(:name)
      end

      def show
        authorize @group
      end

      def create
        group = Group.new

        persist_group(group, :created)
      end

      def update
        persist_group(@group)
      end

      def destroy
        authorize @group
        @group.destroy!

        head :no_content
      end

      private

      def set_group
        @group = policy_scope(Group).find(params[:id])
      end

      def persist_group(group, status = :ok)
        attributes = group_params
        user_ids = normalize_user_ids(attributes.delete(:user_ids))
        admin_user_ids = normalize_user_ids(attributes.delete(:admin_user_ids))
        user_ids = include_current_user(user_ids) if group.new_record?
        admin_user_ids = include_current_user(admin_user_ids) if group.new_record?

        group.assign_attributes(attributes)
        authorize group
        return render_invalid_user_ids(:user_ids) unless valid_user_ids?(user_ids)
        return render_invalid_user_ids(:admin_user_ids) unless valid_user_ids?(admin_user_ids)

        Group.transaction do
          group.save!
          sync_group_memberships(group, user_ids, admin_user_ids)
          ensure_group_has_admin!(group)
        end

        @group = group.reload
        render :show, status:
      rescue ActiveRecord::RecordInvalid
        render_errors(group)
      end

      def group_params
        params.require(:group).permit(:name, :description, :parent_group_id, user_ids: [], admin_user_ids: [])
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

      def sync_group_memberships(group, user_ids, admin_user_ids)
        return if user_ids.nil? && admin_user_ids.nil?

        memberships = group.group_memberships.index_by(&:user_id)
        final_user_ids = user_ids || memberships.keys
        final_admin_user_ids = admin_user_ids || memberships.values.select(&:admin?).map(&:user_id)
        final_user_ids = (final_user_ids + final_admin_user_ids).uniq

        if final_admin_user_ids.empty?
          group.errors.add(:admin_user_ids, :blank)
          raise ActiveRecord::RecordInvalid, group
        end

        final_admin_user_ids.each do |user_id|
          membership = memberships[user_id] || group.group_memberships.build(user_id:)
          membership.admin = true
          membership.save!
        end

        (final_user_ids - final_admin_user_ids).each do |user_id|
          membership = memberships[user_id] || group.group_memberships.build(user_id:)
          membership.admin = false
          membership.save!
        end

        (memberships.keys - final_user_ids).each do |user_id|
          memberships[user_id].destroy!
        end
      end

      def ensure_group_has_admin!(group)
        return if group.group_memberships.reload.any?(&:admin?)

        group.errors.add(:admin_user_ids, :blank)
        raise ActiveRecord::RecordInvalid, group
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

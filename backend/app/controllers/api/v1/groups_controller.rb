module Api
  module V1
    class GroupsController < BaseController
      before_action :set_group, only: [ :show, :update, :destroy ]

      def index
        groups = policy_scope(Group).includes(:parent_group, :users).order(:name)

        render json: groups.map { |group| group_payload(group) }
      end

      def show
        authorize @group

        render json: group_payload(@group)
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
        user_ids = include_current_user(user_ids) if group.new_record?

        group.assign_attributes(attributes)
        authorize group
        return render_invalid_user_ids unless valid_user_ids?(user_ids)

        Group.transaction do
          group.save!
          group.user_ids = user_ids if user_ids
        end

        render json: group_payload(group.reload), status:
      rescue ActiveRecord::RecordInvalid
        render_errors(group)
      end

      def group_params
        params.require(:group).permit(:name, :description, :parent_group_id, user_ids: [])
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

      def render_invalid_user_ids
        render json: { errors: { user_ids: [ "include unknown users" ] } },
               status: :unprocessable_entity
      end
    end
  end
end

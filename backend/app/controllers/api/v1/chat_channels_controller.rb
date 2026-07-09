module Api
  module V1
    class ChatChannelsController < BaseController
      before_action :set_organization, only: [ :index, :create ]
      before_action :set_chat_channel, only: [ :update, :destroy ]

      def index
        authorize ChatChannel
        @chat_channels = policy_scope(@organization.chat_channels)
          .includes(:organization, :chat_conversation)
          .order(:name)
      end

      def create
        chat_channel = @organization.chat_channels.new(channel_params.merge(created_by: current_user))
        authorize chat_channel

        @chat_channel = ::Chats::ChannelCreator.call(
          organization: @organization,
          created_by: current_user,
          attributes: channel_params
        )
        render :show, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render_errors(e.record)
      end

      def update
        authorize @chat_channel

        if @chat_channel.update(channel_params)
          render :show
        else
          render_errors(@chat_channel)
        end
      end

      def destroy
        authorize @chat_channel
        @chat_channel.chat_conversation.destroy!

        head :no_content
      end

      private

      def set_organization
        @organization = policy_scope(Organization).find(params[:organization_id])
      end

      def set_chat_channel
        @chat_channel = policy_scope(ChatChannel).find(params[:id])
      end

      def channel_params
        params.require(:chat_channel).permit(:name, :description)
      end
    end
  end
end

module Api
  module V1
    class DriveItemVersionsController < BaseController
      before_action :set_version

      def content
        authorize @version, :content?
        return render_not_markdown unless @version.markdown?

        render json: { content: @version.markdown_content }
      end

      def download
        authorize @version, :download?

        redirect_to rails_blob_path(@version.file, disposition: "attachment")
      end

      def restore
        authorize @version, :restore?

        @drive_item = @version.drive_item
        @drive_item.restore_version!(@version)
        render "api/v1/drive_items/show"
      end

      private

      def set_version
        @version = policy_scope(DriveItemVersion).includes(:drive_item, file_attachment: :blob).find(params[:id])
      end

      def render_not_markdown
        render "api/v1/errors/show",
          formats: :json,
          locals: { error: "Drive item version is not a Markdown file" },
          status: :unprocessable_entity
      end
    end
  end
end

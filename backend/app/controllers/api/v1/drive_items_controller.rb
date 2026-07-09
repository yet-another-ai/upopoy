module Api
  module V1
    class DriveItemsController < BaseController
      before_action :set_project, only: [ :index, :create ]
      before_action :set_drive_item, only: [
        :show,
        :update,
        :destroy,
        :content,
        :update_content,
        :download,
        :update_file,
        :versions
      ]

      def index
        authorize DriveItem
        @parent = scoped_parent
        @drive_items = policy_scope(@project.drive_items)
          .includes(file_attachment: :blob)
          .where(parent: @parent)
          .ordered
      end

      def create
        drive_item = build_drive_item
        authorize drive_item
        return render_new_item_version_conflict if create_base_version_number.present?

        if drive_item.save
          drive_item.record_version!
          @drive_item = drive_item
          render :show, status: :created
        else
          render_errors(drive_item)
        end
      end

      def show
        authorize @drive_item
      end

      def update
        authorize @drive_item

        if @drive_item.update(drive_item_update_params)
          render :show
        else
          render_errors(@drive_item)
        end
      end

      def destroy
        authorize @drive_item
        @drive_item.soft_delete!

        head :no_content
      end

      def content
        authorize @drive_item, :content?
        return render_not_markdown unless @drive_item.markdown?

        render json: { content: @drive_item.markdown_content }
      end

      def update_content
        authorize @drive_item, :update_content?
        return render_not_markdown unless @drive_item.markdown?
        return render_version_conflict unless matching_base_version?(content_params)

        @drive_item.attach_markdown_content!(content_params[:content])
        if @drive_item.save
          @drive_item.record_version!
          render json: { content: @drive_item.markdown_content }
        else
          render_errors(@drive_item)
        end
      end

      def download
        authorize @drive_item, :download?
        return render_not_file unless @drive_item.file? && @drive_item.file.attached?

        redirect_to rails_blob_path(@drive_item.file, disposition: "attachment")
      end

      def update_file
        authorize @drive_item, :update_file?
        return render_not_file unless @drive_item.file?

        upload = file_params[:file]
        return render_missing_file if upload.blank?
        return render_version_conflict unless matching_base_version?(file_params)

        @drive_item.name = file_params[:name].presence || @drive_item.name
        attach_uploaded_file(@drive_item, upload)
        if @drive_item.save
          @drive_item.record_version!
          render :show
        else
          render_errors(@drive_item)
        end
      end

      def versions
        authorize @drive_item, :versions?
        @versions = @drive_item.versions.includes(file_attachment: :blob).ordered
      end

      private

      def set_project
        @project = policy_scope(Project).find(params[:project_id])
      end

      def set_drive_item
        @drive_item = policy_scope(DriveItem)
          .includes(:project, file_attachment: :blob)
          .find(params[:id])
      end

      def scoped_parent
        return nil if params[:parent_id].blank?

        policy_scope(@project.drive_items).find(params[:parent_id])
      end

      def build_drive_item
        attributes = drive_item_create_params
        kind = attributes[:kind].presence || (attributes[:file].present? ? "file" : "folder")
        drive_item = @project.drive_items.new(
          kind: kind,
          name: attributes[:name],
          parent_id: attributes[:parent_id]
        )

        if kind == "file"
          if attributes[:file].present?
            attach_uploaded_file(drive_item, attributes[:file])
          elsif attributes.key?(:content)
            drive_item.attach_markdown_content!(attributes[:content])
          end
        end

        drive_item
      end

      def attach_uploaded_file(drive_item, upload)
        drive_item.name = drive_item.name.presence || upload.original_filename
        drive_item.file.attach(upload)
        drive_item.text_content_cache = uploaded_markdown_cache(drive_item, upload)
      end

      def uploaded_markdown_cache(drive_item, upload)
        return "" unless drive_item.markdown?

        upload.rewind if upload.respond_to?(:rewind)
        upload.read.to_s.force_encoding(Encoding::UTF_8).scrub
      ensure
        upload.rewind if upload.respond_to?(:rewind)
      end

      def drive_item_create_params
        params.require(:drive_item).permit(:kind, :name, :parent_id, :file, :content, :base_version_number)
      end

      def drive_item_update_params
        params.require(:drive_item).permit(:name, :parent_id)
      end

      def content_params
        params.require(:drive_item).permit(:content, :base_version_number)
      end

      def file_params
        nested_params = params[:drive_item].presence
        return nested_params.permit(:name, :file, :base_version_number) if nested_params.respond_to?(:permit)

        request_params = params[:request_params]
        nested_request_params = request_params[:drive_item] if request_params.respond_to?(:[])
        return nested_request_params.permit(:name, :file, :base_version_number) if nested_request_params.respond_to?(:permit)

        ActionController::Parameters.new(
          name: params[:name] || params["drive_item[name]"] || request_params_name(request_params),
          file: params[:file] || params["drive_item[file]"] || request_params_file(request_params),
          base_version_number: params[:base_version_number] ||
            params["drive_item[base_version_number]"] ||
            request_params_base_version_number(request_params)
        ).permit(:name, :file, :base_version_number)
      end

      def create_base_version_number
        normalize_version_number(drive_item_create_params[:base_version_number])
      end

      def matching_base_version?(permitted_params)
        return false unless permitted_params.key?(:base_version_number)

        normalize_version_number(permitted_params[:base_version_number]) == @drive_item.latest_version_number
      end

      def normalize_version_number(value)
        return nil if value.blank?

        Integer(value)
      rescue ArgumentError, TypeError
        value
      end

      def request_params_name(request_params)
        return unless request_params.respond_to?(:[])

        request_params[:name] || request_params["drive_item[name]"]
      end

      def request_params_file(request_params)
        return unless request_params.respond_to?(:[])

        request_params[:file] || request_params["drive_item[file]"]
      end

      def request_params_base_version_number(request_params)
        return unless request_params.respond_to?(:[])

        request_params[:base_version_number] || request_params["drive_item[base_version_number]"]
      end

      def render_not_markdown
        render "api/v1/errors/show",
          formats: :json,
          locals: { error: "Drive item is not a Markdown file" },
          status: :unprocessable_entity
      end

      def render_not_file
        render "api/v1/errors/show",
          formats: :json,
          locals: { error: "Drive item does not have a file attachment" },
          status: :unprocessable_entity
      end

      def render_missing_file
        render "api/v1/errors/show",
          formats: :json,
          locals: { errors: { file: [ "must be attached" ] } },
          status: :unprocessable_entity
      end

      def render_version_conflict
        render "api/v1/errors/show",
          formats: :json,
          locals: {
            errors: {
              base_version_number: [
                "does not match current version #{@drive_item.latest_version_number.inspect}"
              ]
            }
          },
          status: :conflict
      end

      def render_new_item_version_conflict
        render "api/v1/errors/show",
          formats: :json,
          locals: { errors: { base_version_number: [ "must be nil for new drive items" ] } },
          status: :unprocessable_entity
      end
    end
  end
end

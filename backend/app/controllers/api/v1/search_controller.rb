module Api
  module V1
    class SearchController < BaseController
      VALID_TYPES = SearchDocument::RESOURCE_TYPES.keys.freeze
      DEFAULT_LIMIT = 20
      MAX_LIMIT = 50

      def index
        search_documents = policy_scope(SearchDocument)
        documents = search_query.blank? ? search_documents.none : scoped_search_documents(search_documents)

        render json: {
          results: documents.map { |document| search_result_payload(document) }
        }
      end

      private

      def scoped_search_documents(search_documents)
        search_documents.search(
          query: search_query,
          user: current_user,
          resource_type: resource_type_param,
          limit: limit_param
        )
      end

      def search_query
        params[:q].to_s.strip
      end

      def resource_type_param
        return if params[:type].blank?

        type = params[:type].to_s
        return type if VALID_TYPES.include?(type)

        raise ActionController::BadRequest, "Unknown search type"
      end

      def limit_param
        params.fetch(:limit, DEFAULT_LIMIT).to_i.clamp(1, MAX_LIMIT)
      end

      def search_result_payload(document)
        {
          slug: document.resource_slug,
          type: document.resource_type,
          id: document.searchable_id,
          title: document.title,
          snippet: document.content.to_s.truncate(160),
          api_path: document.api_path,
          metadata: document.metadata,
          updated_at: document.resource_updated_at
        }
      end
    end
  end
end

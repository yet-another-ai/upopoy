module SearchableResource
  extend ActiveSupport::Concern

  included do
    has_one :search_document, as: :searchable, dependent: :destroy

    after_commit :sync_search_document, on: [ :create, :update ], if: :search_document_needs_sync?
    after_commit :delete_search_document, on: :destroy
  end

  class_methods do
    def search_index_attributes(*names)
      @search_index_attribute_names = names.map(&:to_s) if names.any?
      @search_index_attribute_names || []
    end

    def search_resource_type
      name.underscore
    end
  end

  def resource_slug
    "#{self.class.search_resource_type}:#{id}"
  end

  def sync_search_document
    SearchDocument.upsert_for(self)
  end

  def delete_search_document
    SearchDocument.where(searchable_type: self.class.base_class.name, searchable_id: id).delete_all
  end

  private

  def search_document_needs_sync?
    transaction_include_any_action?([ :create ]) ||
      self.class.search_index_attributes.any? { |attribute| previous_changes.key?(attribute) }
  end
end

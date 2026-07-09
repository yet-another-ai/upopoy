module SoftDeletable
  extend ActiveSupport::Concern

  included do
    default_scope { kept }
    scope :kept, -> { where(deleted_at: nil) }
    scope :deleted, -> { with_deleted.where.not(deleted_at: nil) }
    scope :with_deleted, -> { unscope(where: :deleted_at) }

    after_commit :remove_search_document_after_soft_delete, on: :update, if: :saved_change_to_deleted_at?
  end

  def deleted?
    deleted_at.present?
  end

  def kept?
    !deleted?
  end

  def soft_delete!(timestamp: Time.current)
    update!(deleted_at: timestamp)
  end

  def restore!
    update!(deleted_at: nil)
  end

  private

  def remove_search_document_after_soft_delete
    return unless deleted? && respond_to?(:delete_search_document)

    delete_search_document
  end
end

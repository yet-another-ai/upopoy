class Iteration < ApplicationRecord
  belongs_to :project
  has_many :tasks, dependent: :nullify

  validates :name, presence: true
  validates :starts_at, presence: true, unless: :inbox?
  validates :deadline, presence: true, unless: :inbox?
  validates :inbox, uniqueness: { scope: :project_id }, if: :inbox?
  validate :deadline_after_start

  scope :ordered, -> { order(Arel.sql("CASE WHEN inbox THEN 0 ELSE 1 END"), :starts_at, :deadline, :created_at) }

  private

  def deadline_after_start
    return if starts_at.blank? || deadline.blank? || deadline >= starts_at

    errors.add(:deadline, "must be after the start time")
  end
end

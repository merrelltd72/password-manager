class ActivityEvent < ApplicationRecord
  belongs_to :user

  EVENT_TYPES = %w[
    account_created
    account_updated
    account_deleted
    reminder_created
    reminder_completed
  ].freeze

  validates :event_type, inclusion: { in: EVENT_TYPES }

  scope :recent_first, -> { order(created_at: :desc) }
end

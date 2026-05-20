# frozen_string_literal: true

# Model representing an activity event associated with a user, capturing specific actions or changes within the application for auditing and user feedback purposes.
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

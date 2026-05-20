# frozen_string_literal: true

# Model representing an import run, which tracks the status and details of data imports initiated by users.
class ImportRun < ApplicationRecord
  belongs_to :user

  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  validates :format, presence: true, inclusion: { in: %w[csv xlsx json] }

  scope :recent_first, -> { order(created_at: :desc) }

  def mark_processing!
    update!(status: :processing, started_at: Time.current, errpr_message: nil)
  end

  def mark_completed!
    update!(status: :completed, completed_at: Time.current)
  end

  def mark_failed!(message)
    update!(status: :failed, completed_at: Time.current, error_message: message)
  end
end

# frozen_string_literal: true

# Model representing an export operation initiated by a user, tracking its status, format, and associated metadata for file generation and download.
class ExportRun < ApplicationRecord
  belongs_to :user

  enum :status, { pending: 0, in_progress: 1, completed: 2, failed: 3 }

  validates :format, presence: true, inclusion: { in: %w[csv xlsx json] }

  before_validation :assign_download_token, on: :create

  scope :recent_first, -> { order(created_at: :desc) }

  def mark_processing!
    update!(
      status: :in_progress,
      started_at: Time.current,
      error_message: nil
    )
  end

  def mark_completed!(path:, expires_at:, record_count: 0)
    update!(
      status: :completed,
      file_path: path,
      expires_at: expires_at,
      record_count: record_count,
      completed_at: Time.current
    )
  end

  def mark_failed!(message)
    update!(
      status: :failed,
      completed_at: Time.current,
      error_message: message
    )
  end

  private

  def assign_download_token
    self.download_token ||= SecureRandom.hex(24)
  end
end

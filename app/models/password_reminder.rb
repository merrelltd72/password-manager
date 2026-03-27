# frozen_string_literal: true

class PasswordReminder < ApplicationRecord
  belongs_to :account
  belongs_to :user

  validates :reminder_date, presence: true
  validates :notification_sent, inclusion: [true, false]
  validate :reminder_date_must_be_in_the_future, if: :will_save_change_to_reminder_date?

  before_create do
    self.notification_sent = false
  end

  scope :due_reminders, lambda {
    where(notification_sent: false)
      .where('reminder_date <= ?', Date.current)
  }

  def mark_notified!
    update!(notification_sent: true)
  end

  private

  def reminder_date_must_be_in_the_future
    return if reminder_date.blank? || reminder_date > Date.current

    errors.add(:reminder_date, 'must be in the future')
  end
end

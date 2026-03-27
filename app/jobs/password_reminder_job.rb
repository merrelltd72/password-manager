# frozen_string_literal: true

class PasswordReminderJob
  include Sidekiq::Job

  def perform(reminder_id)
    reminder = PasswordReminder.find(reminder_id)
    return if reminder.notification_sent?
    return if reminder.reminder_date > Date.current

    PasswordReminders::Delivery.broadcast(reminder)

    reminder.update!(notification_sent: true)
  rescue ActiveRecord::RecordNotFound
    nil
  end
end

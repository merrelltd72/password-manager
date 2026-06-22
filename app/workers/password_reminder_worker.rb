# frozen_string_literal: true

# This is the password reminder worker class
class PasswordReminderWorker
  include Sidekiq::Worker

  def perform
    PasswordReminder.due_reminders.find_each do |reminder|
      PasswordReminders::Delivery.broadcast(reminder)
      reminder.mark_notified!

      activity_event(reminder)
    end
  end

  private

  def activity_event(reminder)
    ActivityEvent.create!(
      user: reminder.user,
      event_type: 'reminder_completed',
      subject_type: 'PasswordReminder',
      subject_id: reminder.id,
      metadata: { account_id: reminder.account.id, reminder_date: reminder.reminder_date }
    )
  end
end

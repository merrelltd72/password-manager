# frozen_string_literal: true

# This is the password reminder worker class
class PasswordReminderWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'reminders'

  def perform
    due_reminders = Reminder.where(notified: false)

    due_reminders.each do |reminder|
      RemindersChannel.broadcast_to(
        `reminders_#{reminder.account.user.id}`,
        reminder_id: reminder.id,
        message: `Time to update the password for #{reminder.account.username}`
      )

      reminder.update!(notified: true)
    end
  end
end

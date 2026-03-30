# frozen_string_literal: true

# This is the password reminder worker class
class PasswordReminderWorker
  include Sidekiq::Worker

  def perform
    PasswordReminder.due_reminders.find_each do |reminder|
      PasswordReminders::Delivery.broadcast(reminder)
      reminder.mark_notified!
    end
  end
end

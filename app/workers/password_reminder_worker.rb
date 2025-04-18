# frozen_string_literal: true

# This is the password reminder worker class
class PasswordReminderWorker
  include Sidekiq::Worker

  def perform
    PasswordReminder.due_reminders.each do |reminder|
      # Send notification to frontend using ActionCable or a third-party service
      ActionCable.server.broadcast('password_reminders', reminder: reminder)
    end
  end
end

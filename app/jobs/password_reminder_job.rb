# frozen_string_literal: true

class PasswordReminderJob
  include Sidekiq::Job

  def perform(user_id, task_id, scheduled_at)
    user = User.find(user_id)
    task = Task.find(task_id)
    task.reminders.create!(user: user, scheduled_at: scheduled_at)
    NotificationChannel.broadcast_to(user, { task_id: task_id })
  end
end

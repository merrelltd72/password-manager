# frozen_string_literal: true

# This class implements Websockets supporting the Password Reminder funtionality
class PasswordRemindersChannel < ApplicationCable::Channel
  def subscribed
    stream_from `reminders_#{current_user.id}`
  end

  def unsubscribed
    # Not sure if this is needed
  end

  def create(data)
    PasswordReminderService.update_reminder(
      account_id: data['account_id'],
      reminder_date: data['reminder_date']
    )

    broadcast_to(`reminders_#{current_user.id}`,
                 status: 'success',
                 message: 'Reminder updated')
  rescue StandardError => e
    broadcast_to(`reminders_#{current_user.id}`,
                 status: 'error',
                 message: e.message)
  end
end

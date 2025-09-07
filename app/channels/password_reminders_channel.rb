# frozen_string_literal: true

module ApplicationCable
  # This class implements Websockets supporting the Password Reminder funtionality
  class PasswordRemindersChannel < ApplicationCable::Channel
    def subscribed
      stream_from "reminders_#{current_user.id}"
    end

    def unsubscribed
      # Not sure if this is needed
    end

    def update_reminder(data)
      PasswordReminderService.update_reminder(
        account_id: data['account_id'],
        due_date: data['due_date']
      )

      broadcast_to("reminders_#{current_user.id}",
                   status: 'success',
                   message: 'Reminder updated')
    rescue StandardError => e
      broadcast_to("reminders_#{current_user.id}",
                   status: 'error',
                   message: e.message)
    end
  end
end

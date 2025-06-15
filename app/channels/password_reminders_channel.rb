# frozen_string_literal: true

# This class implements Websockets supporting the Password Reminder funtionality
class PasswordRemindersChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'password_reminders'
  end

  def unsubscribed
    # Not sure if this is needed
  end

  def create(data)
    @password_reminder = PasswordReminder.create!(account_id: data['account_id'], user_id: current_user.id,
                                                  reminder_date: data['reminder_date'])
    ActionCable.server.broadcast('password_reminders', reminder: reminder)
  end
end

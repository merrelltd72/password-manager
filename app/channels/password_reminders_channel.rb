# frozen_string_literal: true

# This class implements Websockets supporting the Password Reminder funtionality
class PasswordRemindersChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'password_reminders'
  end

  def create(data)
    raise ArgumentError, 'Invalid data' unless data['account_id'].present? && data['reminder_date'].present?

    @password_reminder = PasswordReminder.create!(account_id: data['account_id'], user_id: current_user.id,
                                                  reminder_date: data['reminder_date'])
    ActionCable.server.broadcast('password_reminders', reminder: @password_reminder)
  rescue ArgumentError => e
    transmit(error: "Validation error: #{e.message}")
  rescue ActiveRecord::RecordInvalid => e
    transmit(error: "Failed to create reminder: #{e.message}")
  rescue StandardError => e
    transmit(error: "An unexpected error occurred: #{e.message}")
  end
end

# frozen_string_literal: true

# This class implements Websockets supporting the Password Reminder funtionality
class PasswordRemindersChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end

  def create(data)
    account_id = data['account_id']
    reminder_date = data['reminder_date']

    raise ArgumentError, 'Invalid data' if account_id.blank? || reminder_date.blank?

    account = current_user.accounts.find(account_id)

    reminder = PasswordReminder.create!(account: account, user: current_user, reminder_date: reminder_date)

    PasswordReminders::Delivery.schedule(reminder)
    PasswordReminders::Delivery.broadcast(reminder)
  rescue ActiveRecord::RecordNotFound
    transmit({ error: 'Account not found or does not belong to the current user' })
  rescue ArgumentError => e
    transmit({ error: "Validation error: #{e.message}" })
  rescue ActiveRecord::RecordInvalid => e
    transmit({ error: "Failed to create reminder: #{e.record.errors.full_messages.join(', ')}" })
  rescue StandardError => e
    transmit({ error: "An unexpected error occurred: #{e.message}" })
  end
end

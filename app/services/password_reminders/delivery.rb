# frozen_string_literal: true

module PasswordReminders
  class Delivery
    def self.schedule(reminder)
      new(reminder).schedule
    end

    def self.broadcast(reminder)
      new(reminder).broadcast
    end

    def initialize(reminder)
      @reminder = reminder
    end

    def schedule
      scheduled_at = reminder.reminder_date.in_time_zone.noon

      if scheduled_at <= Time.current
        PasswordReminderJob.perform_async(reminder.id)
      else
        PasswordReminderJob.perform_at(scheduled_at, reminder.id)
      end
    end

    def broadcast
      PasswordRemindersChannel.broadcast_to(reminder.user, reminder: payload)
    end

    def payload
      {
        id: reminder.id,
        account_id: reminder.account_id,
        user_id: reminder.user_id,
        reminder_date: reminder.reminder_date.iso8601,
        notification_sent: reminder.notification_sent
      }
    end

    private

    attr_reader :reminder
  end
end

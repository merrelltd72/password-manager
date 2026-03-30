# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PasswordReminders::Delivery do
  let(:user) do
    User.create!(
      username: 'service-user',
      email: 'service-user@example.com',
      password: 'password123'
    )
  end

  let(:category) { Category.create!(category_type: 'service') }
  let(:account) { Account.create!(user: user, category: category, web_app_name: '1Password') }

  describe '.schedule' do
    it 'schedules future reminders for noon on the reminder date' do
      reminder = PasswordReminder.create!(account: account, user: user, reminder_date: Date.current + 2.days)
      expected_time = reminder.reminder_date.in_time_zone.noon

      allow(PasswordReminderJob).to receive(:perform_at)

      described_class.schedule(reminder)

      expect(PasswordReminderJob).to have_received(:perform_at).with(expected_time, reminder.id)
    end

    it 'runs immediately when the scheduled time is now or earlier' do
      reminder = PasswordReminder.create!(account: account, user: user, reminder_date: Date.current + 1.day)
      reminder.update_column(:reminder_date, Date.current - 1.day)

      allow(PasswordReminderJob).to receive(:perform_async)

      described_class.schedule(reminder)

      expect(PasswordReminderJob).to have_received(:perform_async).with(reminder.id)
    end
  end

  describe '.broadcast' do
    it 'broadcasts a normalized reminder payload to the reminder owner' do
      reminder = PasswordReminder.create!(account: account, user: user, reminder_date: Date.current + 2.days)

      allow(PasswordRemindersChannel).to receive(:broadcast_to)

      described_class.broadcast(reminder)

      expect(PasswordRemindersChannel).to have_received(:broadcast_to).with(
        user,
        reminder: {
          id: reminder.id,
          account_id: account.id,
          user_id: user.id,
          reminder_date: reminder.reminder_date.iso8601,
          notification_sent: false
        }
      )
    end
  end
end

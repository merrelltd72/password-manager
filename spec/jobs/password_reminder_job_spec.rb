# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PasswordReminderJob, type: :job do
  let(:user) do
    User.create!(
      username: 'job-user',
      email: 'job-user@example.com',
      password: 'password123'
    )
  end

  let(:category) { Category.create!(category_type: 'social') }
  let(:account) { Account.create!(user: user, category: category, web_app_name: 'Slack') }

  it 'broadcasts and marks due reminders as notified' do
    reminder = PasswordReminder.create!(account: account, user: user, reminder_date: Date.current + 1.day)
    reminder.update_column(:reminder_date, Date.current)

    allow(PasswordReminders::Delivery).to receive(:broadcast)

    described_class.new.perform(reminder.id)

    expect(PasswordReminders::Delivery).to have_received(:broadcast).with(reminder)
    expect(reminder.reload.notification_sent).to be(true)
  end

  it 'does not broadcast reminders that are not due yet' do
    reminder = PasswordReminder.create!(account: account, user: user, reminder_date: Date.current + 2.days)

    allow(PasswordReminders::Delivery).to receive(:broadcast)

    described_class.new.perform(reminder.id)

    expect(PasswordReminders::Delivery).not_to have_received(:broadcast)
    expect(reminder.reload.notification_sent).to be(false)
  end
end

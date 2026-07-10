# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PasswordReminderWorker, type: :worker do
  let(:user) do
    User.create!(
      username: 'worker-user',
      email: 'worker-user@example.com',
      password: 'password123'
    )
  end

  let(:category) { Category.create!(category_type: 'ops') }
  let(:account) { Account.create!(user: user, category: category, web_app_name: 'PagerDuty') }

  it 'broadcasts each due reminder and marks it as notified' do
    due_reminder = PasswordReminder.create!(account: account, user: user, reminder_date: Date.current + 1.day)
    due_reminder.update_column(:reminder_date, Date.current)

    future_reminder = PasswordReminder.create!(account: account, user: user, reminder_date: Date.current + 2.days)

    allow(PasswordReminders::Delivery).to receive(:broadcast)

    described_class.new.perform

    expect(PasswordReminders::Delivery).to have_received(:broadcast).with(due_reminder).once
    expect(due_reminder.reload.notification_sent).to be(true)
    expect(future_reminder.reload.notification_sent).to be(false)
  end

  it 'emits a reminder_completed ActivityEvent' do
    due_reminder = PasswordReminder.create!(account: account, user: user, reminder_date: Date.current + 1.day)
    due_reminder.update_column(:reminder_date, Date.current)

    allow(PasswordReminders::Delivery).to receive(:broadcast)

    expect do
      described_class.new.perform
    end.to change { ActivityEvent.where(event_type: 'reminder_completed').count }.by(1)

    event = ActivityEvent.find_by(event_type: 'reminder_completed')
    expect(event.subject_type).to eq('PasswordReminder')
    expect(event.subject_id).to eq(due_reminder.id)
    expect(event.metadata['account_id']).to eq(account.id)
  end
end

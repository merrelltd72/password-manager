# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PasswordReminder, type: :model do
  let(:user) do
    User.create!(
      username: 'model-user',
      email: 'model-user@example.com',
      password: 'password123'
    )
  end

  let(:category) { Category.create!(category_type: 'security') }
  let(:account) { Account.create!(user: user, category: category, web_app_name: 'Vault') }

  describe 'validations' do
    it 'is valid with a future reminder date' do
      reminder = described_class.new(account: account, user: user, reminder_date: Date.current + 1.day)

      expect(reminder).to be_valid
    end

    it 'requires the reminder date to be in the future' do
      reminder = described_class.new(account: account, user: user, reminder_date: Date.current)

      expect(reminder).not_to be_valid
      expect(reminder.errors[:reminder_date]).to include('must be in the future')
    end

    it 'defaults notification_sent to false before create' do
      reminder = described_class.create!(account: account, user: user, reminder_date: Date.current + 1.day)

      expect(reminder.notification_sent).to be(false)
    end
  end

  describe '.due_reminders' do
    it 'returns reminders due today or earlier that have not been sent' do
      due_reminder = described_class.create!(account: account, user: user, reminder_date: Date.current + 1.day)
      due_reminder.update_column(:reminder_date, Date.current)

      sent_reminder = described_class.create!(account: account, user: user, reminder_date: Date.current + 2.days)
      sent_reminder.update_columns(reminder_date: Date.current, notification_sent: true)

      future_reminder = described_class.create!(account: account, user: user, reminder_date: Date.current + 3.days)

      expect(described_class.due_reminders).to contain_exactly(due_reminder)
      expect(described_class.due_reminders).not_to include(sent_reminder, future_reminder)
    end
  end

  describe '#mark_notified!' do
    it 'marks the reminder as notified' do
      reminder = described_class.create!(account: account, user: user, reminder_date: Date.current + 1.day)

      reminder.mark_notified!

      expect(reminder.reload.notification_sent).to be(true)
    end
  end
end

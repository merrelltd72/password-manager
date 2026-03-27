# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PasswordRemindersChannel, type: :channel do
  let(:user) do
    User.create!(
      username: 'channel-user',
      email: 'channel-user@example.com',
      password: 'password123'
    )
  end

  let(:category) { Category.create!(category_type: 'finance') }
  let(:account) { Account.create!(user: user, category: category, web_app_name: 'Bank') }

  before do
    stub_connection(current_user: user)
  end

  describe '#subscribed' do
    it 'streams reminders for the current user' do
      subscribe

      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_for(user)
    end
  end

  describe '#create' do
    it 'creates a reminder, schedules it, and broadcasts it to the current user' do
      allow(PasswordReminders::Delivery).to receive(:schedule)
      allow(PasswordReminders::Delivery).to receive(:broadcast)

      subscribe

      expect do
        perform :create, { account_id: account.id, reminder_date: (Date.current + 1.day).iso8601 }
      end.to change(PasswordReminder, :count).by(1)

      reminder = PasswordReminder.order(:id).last

      expect(PasswordReminders::Delivery).to have_received(:schedule).with(reminder)
      expect(PasswordReminders::Delivery).to have_received(:broadcast).with(reminder)
    end

    it 'transmits an error when the account is missing' do
      subscribe

      perform :create, { account_id: account.id + 1000, reminder_date: (Date.current + 1.day).iso8601 }

      expect(transmissions.last).to eq('error' => 'Account not found or does not belong to the current user')
    end
  end
end

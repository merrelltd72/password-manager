# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PasswordReminders', type: :request do
  let(:user) do
    User.create!(
      username: 'request-user',
      email: 'request-user@example.com',
      password: 'password123'
    )
  end

  let(:category) { Category.create!(category_type: 'productivity') }
  let(:account) { Account.create!(user: user, category: category, web_app_name: 'Notion') }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe 'POST /reminders' do
    let(:params) do
      {
        password_reminder: {
          account_id: account.id,
          reminder_date: reminder_date
        }
      }
    end

    context 'when the reminder date is in the future' do
      let(:reminder_date) { Date.current + 3.days }

      it 'schedules the reminder job for noon on the reminder date' do
        expected_time = reminder_date.in_time_zone.noon

        allow(PasswordReminderJob).to receive(:perform_at)

        post '/reminders', params: params

        reminder = PasswordReminder.order(:id).last

        expect(response).to have_http_status(:created)
        expect(reminder.user).to eq(user)
        expect(PasswordReminderJob).to have_received(:perform_at).with(expected_time, reminder.id)
      end
    end

    context 'when the reminder date is today' do
      let(:reminder_date) { Date.current }

      it 'returns an error because the reminder date must be in the future' do
        allow(PasswordReminderJob).to receive(:perform_async)

        post '/reminders', params: params

        expect(response).to have_http_status(422)
        expect(PasswordReminderJob).not_to have_received(:perform_async)
      end
    end

    context 'when the user is not authenticated' do
      let(:reminder_date) { Date.current + 3.days }

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
      end

      it 'returns unauthorized and does not create a reminder' do
        allow(PasswordReminderJob).to receive(:perform_at)

        expect do
          post '/reminders', params: params
        end.not_to change(PasswordReminder, :count)

        expect(response).to have_http_status(:unauthorized)
        expect(PasswordReminderJob).not_to have_received(:perform_at)
      end
    end
  end
end

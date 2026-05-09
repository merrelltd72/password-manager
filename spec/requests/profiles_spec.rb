# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profile', type: :request do
  let(:user) { User.create!(username: 'profileuser', email: 'profile@example.com', password: 'Password1!') }

  before do
    post '/sessions', params: { email: user.email, password: 'Password1!' }
    expect(response).to have_http_status(:created)
  end

  it 'shows profile' do
    get '/profile'
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body).to include('identity', 'preferences', 'security', 'data_controls')
  end

  it 'updates username and preferences' do
    patch '/profile', params: {
      username: 'updated_name',
      preferences: {
        timezone: 'UTC',
        date_format: 'yyyy-MM-dd',
        generator_defaults: { length: 20, symbols: true, numbers: true, uppercase: true },
        reminder_defaults: { lead_days: 10, repeat: 'monthly' }
      }
    }, as: :json

    expect(response).to have_http_status(:ok)
    expect(user.reload.username).to eq('updated_name')
  end

  it 'changes password with correct current password' do
    patch '/profile/password', params: {
      current_password: 'Password1!',
      new_password: 'Password2!',
      new_password_confirmation: 'Password2!'
    }

    expect(response).to have_http_status(:ok)
  end
end

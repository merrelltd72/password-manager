# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profile' do
  let(:user) { User.create!(username: 'profileuser', email: 'profile@example.com', password: 'Password1!') }

  before do
    post '/sessions', params: { email: user.email, password: 'Password1!' }
    expect(response).to have_http_status(:created)
  end

  it 'shows profile' do
    get '/profile'
    expect(response).to have_http_status(:ok)
    body = response.parsed_body
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

  it 'returns active_sessions_supported: true' do
    get '/profile'
    body = response.parsed_body
    expect(body.dig('security', 'active_sessions_supported')).to be(true)
  end

  describe 'DELETE /profile' do
    it 'deletes accont with confirm_text' do
      delete '/profile', params: { confirm_text: 'DELETE' }, as: :json

      expect(response).to have_http_status(:ok)
      expect(User.find_by(id: user.id)).to be_nil
    end

    it 'deletes account with valid current_password' do
      delete '/profile', params: { current_password: 'Password1!' }, as: :json

      expect(response).to have_http_status(:ok)
      expect(User.find_by(id: user.id)).to be_nil
    end

    it 'rejects delete without confirmation' do
      delete '/profile', params: {}, as: :json

      expect_json_error_response(:unprocessable_entity)
    end

    it 'rejects unauthenticated delete' do
      delete '/sessions'
      delete '/profile', params: { confirm_text: 'DELETE' }, as: :json

      expect_json_error_response(:unauthorized)
    end
  end

  describe 'POST /profile/sign_out_all' do
    it 'revokes all active sessions' do
      # Simulate a second device by logging in again
      post '/sessions', params: { email: user.email, password: 'Password1!' }
      expect(UserSession.for_user(user).active.count).to eq(2)

      post '/profile/sign_out_all'

      expect(response).to have_http_status(:ok)
      expect(UserSession.for_user(user).active.count).to eq(0)
    end

    it 'returns 401 on subsequent requests after sign_out_all' do
      post '/profile/sign_out_all'
      get '/dashboard'
      expect_json_error_response(:unauthorized)
    end
  end

  describe 'PATCH /profile/password session revocation' do
    it 'revokes all existing sessions and issues a fresh one' do
      old_session = UserSession.for_user(user).last

      patch '/profile/password', params: {
        current_password: 'Password1!',
        new_password: 'Password2!',
        new_password_confirmation: 'Password2!'
      }

      expect(response).to have_http_status(:ok)
      expect(old_session.reload.revoked_at).to be_present
      expect(UserSession.for_user(user).active.count).to eq(1)
    end
  end
end

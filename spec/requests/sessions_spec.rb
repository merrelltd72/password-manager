# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sessions', type: :request do
  def parsed_body
    JSON.parse(response.body)
  end

  def with_omniauth_auth(auth_hash)
    allow_any_instance_of(ActionDispatch::Request).to receive(:env).and_wrap_original do |original, *args|
      original.call(*args).merge('omniauth.auth' => auth_hash)
    end
  end

  describe 'POST /sessions' do
    context 'when the provider returns a valid auth hash' do
      let!(:existing_user) do
        User.create!(
          username: 'OAuth User',
          email: 'oauth-user@example.com',
          password: 'password123',
          provider: 'google_oauth2',
          uid: 'old-uid',
          token: 'old-token'
        )
      end

      let(:auth_hash) do
        OmniAuth::AuthHash.new(
          provider: 'google_oauth2',
          uid: 'google-uid-123',
          info: {
            email: 'oauth-user@example.com',
            name: 'OAuth User'
          },
          credentials: {
            token: 'oauth-token-123'
          }
        )
      end

      before do
        with_omniauth_auth(auth_hash)
        allow_any_instance_of(SessionsController).to receive(:issue_jwt).and_return('jwt-token')
      end

      it 'creates a session and updates oauth fields on the user' do
        post '/sessions'

        user = User.find_by(email: 'oauth-user@example.com')

        expect(response).to have_http_status(:created)
        expect(parsed_body['email']).to eq('oauth-user@example.com')
        expect(parsed_body['user_id']).to eq(existing_user.id)
        expect(user.provider).to eq('google_oauth2')
        expect(user.uid).to eq('google-uid-123')
        expect(user.token).to eq('oauth-token-123')
      end
    end

    context 'when no oauth auth hash is present' do
      it 'returns unauthorized' do
        post '/sessions'

        expect(response).to have_http_status(:unauthorized)
        expect(parsed_body['error']).to eq('Invalid credentials')
      end
    end

    context 'when the provider payload is malformed' do
      let(:malformed_auth) do
        OmniAuth::AuthHash.new(
          provider: 'google_oauth2',
          uid: 'google-uid-500',
          info: nil,
          credentials: {
            token: 'token'
          }
        )
      end

      before do
        with_omniauth_auth(malformed_auth)
      end

      it 'returns internal server error' do
        post '/sessions'

        expect(response).to have_http_status(:internal_server_error)
        expect(parsed_body['error']).to eq('Authentication failed')
      end
    end
  end
end

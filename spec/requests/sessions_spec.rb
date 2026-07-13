# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sessions' do
  delegate :parsed_body, to: :response

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

        expect_json_error_response(:unauthorized)
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

        expect_json_error_response(:internal_server_error)
      end
    end
  end

  describe 'POST /sessions (email/password)' do
    let(:user) { User.create!(username: 'emailuser', email: 'email@example.com', password: 'Password1!') }

    it 'creates a UserSession record on successful login' do
      expect do
        post '/sessions', params: { email: user.email, password: 'Password1!' }
      end.to change(UserSession, :count).by(1)

      expect(response).to have_http_status(:created)
      session = UserSession.last
      expect(session.user).to eq(user)
      expect(session.jti).to be_present
      expect(session.expires_at).to be_within(5.seconds).of(30.minutes.from_now)
    end

    it 'does not create a UserSession on failed login' do
      expect do
        post '/sessions', params: { email: user.email, password: 'wrong' }
      end.not_to(change(UserSession, :count))

      expect_json_error_response(:unauthorized)
    end
  end

  describe 'DELETE /sessions' do
    let(:user) { User.create!(username: 'logoutuser', email: 'logout@example.com', password: 'Password1!') }

    before { post '/sessions', params: { email: user.email, password: 'Password1!' } }

    it 'revokes the UserSession on logout' do
      session = UserSession.last
      delete '/sessions'

      expect(response).to have_http_status(:ok)
      expect(session.reload.revoked_at).to be_present
    end

    it 'returns 401 on subsequent requests after logout' do
      delete '/sessions'
      get '/dashboard'
      expect_json_error_response(:unauthorized)
    end
  end

  describe 'revoked session' do
    let(:user) { User.create!(username: 'revokeduser', email: 'revoked@example.com', password: 'Password1!') }

    it 'returns 401 when the session record has been revoked' do
      post '/sessions', params: { email: user.email, password: 'Password1!' }
      UserSession.last.revoke!

      get '/dashboard'
      expect_json_error_response(:unauthorized)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard', type: :request do
  let(:user) { User.create!(username: 'dashuser', email: 'dash@example.com', password: 'Password1!') }

  before do
    post '/sessions', params: { email: user.email, password: 'Password1!' }
    expect(response).to have_http_status(:created)
  end

  it 'returns dashboard payload for authenticated user' do
    get '/dashboard'
    expect(response).to have_http_status(:ok)

    body = JSON.parse(response.body)
    expect(body).to include('summary', 'security', 'reminders', 'activity', 'empty_state')
  end

  it 'rejects unauthenticated request' do
    delete '/sessions'
    get '/dashboard'
    expect_json_error_response(:unauthorized)
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard' do
  let(:user) { User.create!(username: 'dashuser', email: 'dash@example.com', password: 'Password1!') }

  before do
    post '/sessions', params: { email: user.email, password: 'Password1!' }
    expect(response).to have_http_status(:created)
  end

  it 'returns dashboard payload for authenticated user' do
    get '/dashboard'
    expect(response).to have_http_status(:ok)

    body = response.parsed_body
    expect(body).to include('summary', 'security', 'reminders', 'activity', 'empty_state')
  end

  it 'rejects unauthenticated request' do
    delete '/sessions'
    get '/dashboard'
    expect_json_error_response(:unauthorized)
  end

  it 'returns activity with next_cursor when events exceed limit' do
    16.times { ActivityEvent.create!(user: user, event_type: 'account_created') }

    get '/dashboard'

    body = response.parsed_body
    expect(body['activity']['next_cursor']).to be_a(String).and be_present
    expect(body['activity']['events'].size).to eq(15)
  end

  it 'paginates activity with cursor param' do
    20.times { ActivityEvent.create!(user: user, event_type: 'account_created') }

    get '/dashboard', params: { limit: 10 }
    first_ids = response.parsed_body.dig('activity', 'events').pluck('id')
    cursor    = response.parsed_body.dig('activity', 'next_cursor')

    get '/dashboard', params: { limit: 10, cursor: cursor }
    second_ids = response.parsed_body.dig('activity', 'events').pluck('id')

    expect(first_ids & second_ids).to be_empty
  end
end

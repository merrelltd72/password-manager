# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Imports', type: :request do
  let(:user) do
    User.create!(
      username: 'importuser',
      email: 'importuser@example.com',
      password: 'Password1!'
    )
  end

  let(:user2) do
    User.create!(
      username: 'importuser2',
      email: 'importuser2@example.com',
      password: 'Password1!'
    )
  end

  def login_as(current_user)
    post '/sessions', params: { email: current_user.email, password: 'Password1!' }
    expect(response).to have_http_status(:created)
  end

  describe 'GET /imports' do
    context 'when authenticated' do
      before { login_as(user) }

      it 'returns only current user import runs' do
        user.import_runs.create!(format: 'csv', status: :completed)
        user2.import_runs.create!(format: 'xlsx', status: :failed)

        get '/imports'

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)

        expect(body['imports']).to be_an(Array)
        expect(body['imports'].size).to eq(1)
        expect(body['imports'].first['format']).to eq('csv')
      end

      it 'respects limit param' do
        3.times { user.import_runs.create!(format: 'csv', status: :completed) }

        get '/imports', params: { limit: 2 }

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['imports'].size).to eq(2)
      end
    end

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        get '/imports'

        expect_json_error_response(:unauthorized)
      end
    end
  end
end

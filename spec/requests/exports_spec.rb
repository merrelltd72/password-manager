# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Exports', type: :request do
  let(:user) do
    User.create!(
      username: 'user',
      email: 'user@example.com',
      password: 'Password1'
    )
  end

  let(:user2) do
    User.create!(
      username: 'user2',
      email: 'user2@example.com',
      password: 'Password2'
    )
  end

  def login_as(current_user)
    post '/sessions', params: { email: current_user.email, password: 'Password1' }
    expect(response).to have_http_status(:created)
  end

  describe 'POST /exports/accounts' do
    context 'when authenticated' do
      before { login_as(user) }

      it 'creates an export run' do
        expect do
          post '/exports/accounts', params: { format: 'csv' }, as: :json
        end.to change { user.export_runs.count }.by(1)

        expect(response).to have_http_status(:accepted)

        body = JSON.parse(response.body)
        expect(body).to include('id', 'status', 'format')
        expect(body['format']).to eq('csv')
      end

      it 'defaults to csv when format is omitted' do
        post '/exports/accounts', params: {}, as: :json

        expect(response).to have_http_status(:accepted)

        body = JSON.parse(response.body)
        expect(body['format']).to eq('csv')
      end
    end

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        post '/exports/accounts', params: { format: 'csv' }, as: :json
        expect_json_error_response(:unauthorized)
      end
    end
  end

  describe 'GET /exports/:id' do
    context 'when authenticated' do
      before { login_as(user) }

      it 'returns own export run' do
        run = user.export_runs.create!(format: 'csv')

        get "/exports/#{run.id}"

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['id']).to eq(run.id)
        expect(body['format']).to eq('csv')
      end

      it 'does not expose another users export run' do
        run2 = user2.export_runs.create!(format: 'csv')

        get "/exports/#{run2.id}"

        expect_json_error_response(:not_found)
      end

      it 'returns a download_url when all conditions are met' do
        run = user.export_runs.create!(
          format: 'csv',
          status: :completed,
          file_path: '/tmp/export.csv',
          expires_at: 1.day.from_now
        )

        get "/exports/#{run.id}"

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['download_url']).to eq("/exports/#{run.id}/download?token=#{run.download_token}")
      end

      it 'returns nil download_url when export is expired' do
        run = user.export_runs.create!(
          format: 'csv',
          status: :completed,
          file_path: '/tmp/export.csv',
          expires_at: 1.day.ago
        )

        get "/exports/#{run.id}"

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['download_url']).to be_nil
      end

      it 'returns nil download_url when completed export has no file_path' do
        run = user.export_runs.create!(
          format: 'csv',
          status: :completed,
          file_path: nil,
          expires_at: 1.day.from_now
        )

        get "/exports/#{run.id}"

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['download_url']).to be_nil
      end
    end

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        run = user.export_runs.create!(format: 'csv')

        get "/exports/#{run.id}"

        expect_json_error_response(:unauthorized)
      end
    end
  end

  describe 'GET /exports/:id/download' do
    context 'when authenticated' do
      before { login_as(user) }

      it 'downloads completed export with valid token' do
        run = user.export_runs.create!(
          format: 'csv',
          status: :completed,
          file_path: Rails.root.join('tmp', 'exports', 'test.csv').to_s,
          expires_at: 1.day.from_now
        )
        FileUtils.mkdir_p(File.dirname(run.file_path))
        File.write(run.file_path, "id,web_app_name\n1,Github\n")

        get "/exports/#{run.id}/download", params: { token: run.download_token }

        expect(response).to have_http_status(:ok)
      end

      it 'rejects expired exports' do
        run = user.export_runs.create!(
          format: 'csv',
          status: :completed,
          file_path: '/tmp/export.csv',
          expires_at: 1.day.ago
        )

        get "/exports/#{run.id}/download", params: { token: run.download_token }

        expect(response).to have_http_status(:gone)
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExportRun, type: :model do
  let(:user) { User.create!(username: 'testuser', email: 'testuser@example.com', password: 'password1') }

  it 'is invalid without a format' do
    run = ExportRun.new(user: user)
    expect(run).not_to be_valid
    expect(run.errors[:format]).to include("can't be blank")
  end

  it 'is invalid with an unsupported format' do
    run = ExportRun.new(user: user, format: 'xml')
    expect(run).not_to be_valid
    expect(run.errors[:format]).to include('is not included in the list')
  end

  %w[csv xlsx json].each do |format|
    it "is valid with format #{format}" do
      run = ExportRun.new(user: user, format: format)
      expect(run).to be_valid
    end
  end

  it 'is invalid without a user' do
    run = ExportRun.new(format: 'csv')
    expect(run).not_to be_valid
    expect(run.errors[:user]).to include('must exist')
  end

  it 'assigns a download token on creation' do
    run = ExportRun.create!(user: user, format: 'csv')
    expect(run.download_token).to be_present
  end

  it 'does not overwrite a pre-set download token' do
    run = ExportRun.create!(user: user, format: 'csv', download_token: 'mytoken')
    expect(run.download_token).to eq('mytoken')
  end

  describe '#mark_processing!' do
    it 'sets status to in_progress and records started_at' do
      run = ExportRun.create!(user: user, format: 'csv')
      run.mark_processing!
    end
  end

  it 'clears a prior error_message' do
    run = ExportRun.create!(user: user, format: 'csv')
    run.update_columns(error_message: 'prior error')
    run.mark_processing!

    expect(run.reload.error_message).to be_nil
  end

  describe '#mark_completed!' do
    it 'sets status to completed with file metadata' do
      run = ExportRun.create!(user: user, format: 'csv')
      expires = 1.day.from_now
      run.mark_completed!(path: '/tmp/export.csv', expires_at: expires, record_count: 5)

      run.reload
      expect(run.status).to eq('completed')
      expect(run.file_path).to eq('/tmp/export.csv')
      expect(run.expires_at).to be_within(1.second).of(expires)
      expect(run.record_count).to eq(5)
      expect(run.completed_at).to be_present
    end
  end

  describe '#mark_failed!' do
    it 'sets status to failed with error message and completed_at' do
      run = ExportRun.create!(user: user, format: 'csv')
      run.mark_failed!('something went wrong')

      run.reload
      expect(run.status).to eq('failed')
      expect(run.error_message).to eq('something went wrong')
      expect(run.completed_at).to be_present
    end
  end

  describe '.recent_first' do
    it 'orders records newest first' do
      old_run = ExportRun.create!(user: user, format: 'csv', created_at: 2.days.ago)
      new_run = ExportRun.create!(user: user, format: 'json')

      expect(ExportRun.recent_first.first).to eq(new_run)
      expect(ExportRun.recent_first.last).to eq(old_run)
    end
  end
end

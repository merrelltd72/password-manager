# frozen_string_literal: true

require 'rails_helper'
require 'fileutils'

RSpec.describe Exports::CleanupExpiredJob, type: :job do
  let(:user) do
    User.create!(
      username: 'cleanup-job-user',
      email: 'cleanup-job-user@example.com',
      password: 'Password1!'
    )
  end

  describe '#perform' do
    it 'deletes files and clears file_path for expired completed runs' do
      file_path = Rails.root.join('tmp', 'exports', user.id.to_s, 'expired.csv').to_s
      FileUtils.mkdir_p(File.dirname(file_path))
      File.write(file_path, "id,web_app_name\n1,GitHub\n")

      expired_run = user.export_runs.create!(
        format: 'csv',
        status: :completed,
        file_path: file_path,
        expires_at: 2.days.ago
      )

      described_class.perform_now

      expect(File.exist?(file_path)).to be(false)
      expect(expired_run.reload.file_path).to be_nil
    end

    it 'does not touch non-expired completed runs' do
      file_path = Rails.root.join('tmp', 'exports', user.id.to_s, 'fresh.csv').to_s
      FileUtils.mkdir_p(File.dirname(file_path))
      File.write(file_path, "id,web_app_name\n1,GitHub\n")

      fresh_run = user.export_runs.create!(
        format: 'csv',
        status: :completed,
        file_path: file_path,
        expires_at: 2.days.from_now
      )

      described_class.perform_now

      expect(File.exist?(file_path)).to be(true)
      expect(fresh_run.reload.file_path).to eq(file_path)
    ensure
      FileUtils.rm_f(file_path)
    end

    it 'skips non-completed runs even if expired' do
      run = user.export_runs.create!(
        format: 'csv',
        status: :failed,
        file_path: '/tmp/failed.csv',
        expires_at: 2.days.ago
      )

      described_class.perform_now

      expect(run.reload.file_path).to eq('/tmp/failed.csv')
      expect(run).to be_failed
    end

    it 'handles missing files gracefully and still clears file_path' do
      missing_file = Rails.root.join('tmp', 'exports', user.id.to_s, 'missing.csv').to_s

      run = user.export_runs.create!(
        format: 'csv',
        status: :completed,
        file_path: missing_file,
        expires_at: 1.day.ago
      )

      expect(File.exist?(missing_file)).to be(false)

      expect { described_class.perform_now }.not_to raise_error
      expect(run.reload.file_path).to be_nil
    end
  end
end

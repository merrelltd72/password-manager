# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Exports::GenerateFileJob, type: :job do
  let(:user) do
    User.create!(
      username: 'export-job-user',
      email: 'export-job-user@example.com',
      password: 'Password1!'
    )
  end

  describe '#perform' do
    it 'processes a pending run and marks it completed' do
      run = user.export_runs.create!(format: 'csv', status: :pending)

      generated = {
        path: '/tmp/export_123.csv',
        record_count: 5,
        expires_at: 7.days.from_now
      }

      allow(Exports::FileBuilder).to receive(:call).with(run: run).and_return(generated)

      described_class.perform_now(run.id)

      run.reload
      expect(run).to be_completed
      expect(run.file_path).to eq('/tmp/export_123.csv')
      expect(run.record_count).to eq(5)
      expect(run.expires_at.to_i).to eq(generated[:expires_at].to_i)
      expect(run.started_at).to be_present
      expect(run.completed_at).to be_present
      expect(run.error_message).to be_nil
    end

    it 'processes a failed run again' do
      run = user.export_runs.create!(
        format: 'csv',
        status: :failed,
        error_message: 'previous error'
      )

      generated = {
        path: '/tmp/export_retry.csv',
        record_count: 2,
        expires_at: 7.days.from_now
      }

      allow(Exports::FileBuilder).to receive(:call).with(run: run).and_return(generated)

      described_class.perform_now(run.id)

      run.reload
      expect(run).to be_completed
      expect(run.file_path).to eq('/tmp/export_retry.csv')
      expect(run.record_count).to eq(2)
      expect(run.error_message).to be_nil
    end

    it 'does nothing for already completed runs' do
      run = user.export_runs.create!(
        format: 'csv',
        status: :completed,
        file_path: '/tmp/already.csv',
        expires_at: 1.day.from_now
      )

      allow(Exports::FileBuilder).to receive(:call)

      described_class.perform_now(run.id)

      expect(Exports::FileBuilder).not_to have_received(:call)
      expect(run.reload.file_path).to eq('/tmp/already.csv')
    end

    it 'no-ops when the run does not exist' do
      expect { described_class.perform_now(-1) }.not_to raise_error
    end

    it 'marks run failed and re-raises when builder errors' do
      run = user.export_runs.create!(format: 'csv', status: :pending)

      allow(Exports::FileBuilder).to receive(:call).with(run: run).and_raise(StandardError, 'boom')

      expect { described_class.new.perform(run.id) }.to raise_error(StandardError, 'boom')

      run.reload
      expect(run).to be_failed
      expect(run.error_message).to eq('boom')
      expect(run.completed_at).to be_present
    end
  end
end

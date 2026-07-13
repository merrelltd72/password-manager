# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImportRun do
  let(:user) { User.create!(username: 'runuser', email: 'run@example.com', password: 'Password1!') }

  describe 'validations' do
    it 'requires a format' do
      run = described_class.new(user: user)
      expect(run).not_to be_valid
      expect(run.errors[:format]).to be_present
    end

    it 'rejects unsupported formats' do
      run = described_class.new(user: user, format: 'xml')
      expect(run).not_to be_valid
    end

    it 'accepts csv, xlsx, and json' do
      %w[csv xlsx json].each do |fmt|
        run = described_class.new(user: user, format: fmt)
        expect(run).to be_valid, "Expected format '#{fmt}' to be valid"
      end
    end
  end

  describe 'lifecycle' do
    let(:run) { described_class.create!(user: user, format: 'csv') }

    it 'starts as pending' do
      expect(run.status).to eq('pending')
    end

    describe '#mark_processing!' do
      it 'transitions to processing and records started_at' do
        run.mark_processing!
        expect(run.reload.status).to eq('processing')
        expect(run.started_at).to be_present
        expect(run.error_message).to be_nil
      end
    end

    describe '#mark_completed!' do
      it 'transitions to completed and records completed_at' do
        run.mark_processing!
        run.mark_completed!
        expect(run.reload.status).to eq('completed')
        expect(run.completed_at).to be_present
      end
    end

    describe '#mark_failed!' do
      it 'transitions to failed and stores the error message' do
        run.mark_processing!
        run.mark_failed!('parse error')
        expect(run.reload.status).to eq('failed')
        expect(run.error_message).to eq('parse error')
        expect(run.completed_at).to be_present
      end
    end
  end

  describe '.recent_first' do
    it 'orders runs newest first' do
      older = described_class.create!(user: user, format: 'csv', created_at: 2.hours.ago)
      newer = described_class.create!(user: user, format: 'xlsx', created_at: 1.hour.ago)

      expect(described_class.recent_first.first).to eq(newer)
      expect(described_class.recent_first.last).to eq(older)
    end
  end
end

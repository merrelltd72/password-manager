# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActivityEvent, type: :model do
  let(:user) { User.create!(username: 'user', email: 'user@example.com', password: 'Password1!') }

  describe 'validations' do
    it 'accepts all defined EVENT_TYPES' do
      ActivityEvent::EVENT_TYPES.each do |type|
        event = ActivityEvent.new(user: user, event_type: type)
        expect(event).to be_valid, "Expected #{type} to be valid"
      end
    end

    it 'rejects an unknown event_type' do
      event = ActivityEvent.new(user: user, event_type: 'unknown_event')
      expect(event).not_to be_valid
      expect(event.errors[:event_type]).to be_present
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe '.recent_first' do
    it 'orders events newest first' do
      older = ActivityEvent.create!(user: user, event_type: 'account_created', created_at: 2.hours.ago)
      newer = ActivityEvent.create!(user: user, event_type: 'account_updated', created_at: 1.hour.ago)

      expect(ActivityEvent.recent_first.first).to eq(newer)
      expect(ActivityEvent.recent_first.last).to eq(older)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserPreference do
  let(:user) { User.create!(username: 'prefuser', email: 'pref@example.com', password: 'Password1!') }

  let(:valid_attrs) do
    {
      user: user,
      timezone: 'UTC',
      date_format: 'yyyy-MM-dd',
      generator_defaults: { length: 16, symbols: true, numbers: true, uppercase: true },
      reminder_defaults: { lead_days: 7, repeat: 'monthly' }
    }
  end

  it 'is valid with valid attributes' do
    expect(described_class.new(valid_attrs)).to be_valid
  end

  describe 'REPEAT_VALUES' do
    it 'is exactly %w[none weekly monthly quarterly]' do
      expect(UserPreference::REPEAT_VALUES).to eq(%w[none weekly monthly quarterly])
    end

    it 'does not include yearly' do
      expect(UserPreference::REPEAT_VALUES).not_to include('yearly')
    end
  end

  describe 'timezone validation' do
    it 'rejects blank timezone' do
      pref = described_class.new(valid_attrs.merge(timezone: ''))
      expect(pref).not_to be_valid
      expect(pref.errors[:timezone]).to be_present
    end

    it 'rejects an unrecognized timezone string' do
      pref = described_class.new(valid_attrs.merge(timezone: 'Mars/Olympus'))
      expect(pref).not_to be_valid
      expect(pref.errors[:timezone]).to include('is invalid')
    end

    it 'accepts a valid ActiveSupport timezone name' do
      pref = described_class.new(valid_attrs.merge(timezone: 'Eastern Time (US & Canada)'))
      expect(pref).to be_valid
    end
  end

  describe 'generator_defaults validation' do
    it 'rejects length below 8' do
      pref = described_class.new(valid_attrs.merge(
                                   generator_defaults: { length: 4, symbols: true, numbers: true, uppercase: true }
                                 ))
      expect(pref).not_to be_valid
      expect(pref.errors[:generator_defaults]).to include(include('length must be'))
    end

    it 'rejects length above 64' do
      pref = described_class.new(valid_attrs.merge(
                                   generator_defaults: { length: 128, symbols: true, numbers: true, uppercase: true }
                                 ))
      expect(pref).not_to be_valid
    end

    it 'rejects non-boolean symbols' do
      pref = described_class.new(valid_attrs.merge(
                                   generator_defaults: { length: 16, symbols: 'yes', numbers: true, uppercase: true }
                                 ))
      expect(pref).not_to be_valid
      expect(pref.errors[:generator_defaults]).to include('symbols must be boolean')
    end
  end

  describe 'reminder_defaults validation' do
    it 'rejects lead_days below 0' do
      pref = described_class.new(valid_attrs.merge(reminder_defaults: { lead_days: -1, repeat: 'monthly' }))
      expect(pref).not_to be_valid
    end

    it 'rejects lead_days above 365' do
      pref = described_class.new(valid_attrs.merge(reminder_defaults: { lead_days: 400, repeat: 'monthly' }))
      expect(pref).not_to be_valid
    end

    it 'rejects an invalid repeat value' do
      pref = described_class.new(valid_attrs.merge(reminder_defaults: { lead_days: 7, repeat: 'yearly' }))
      expect(pref).not_to be_valid
      expect(pref.errors[:reminder_defaults]).to include(include('repeat must be one of'))
    end

    it 'accepts all canonical repeat values' do
      UserPreference::REPEAT_VALUES.each do |repeat|
        pref = described_class.new(valid_attrs.merge(reminder_defaults: { lead_days: 7, repeat: repeat }))
        expect(pref).to be_valid, "Expected repeat '#{repeat}' to be valid"
      end
    end
  end
end

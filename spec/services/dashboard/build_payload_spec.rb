# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::BuildPayload, type: :service do
  let(:user) { User.create!(username: 'dashsvc', email: 'dashsvc@example.com', password: 'Password1!') }
  let(:category) { Category.create!(category_type: 'ops') }

  def create_account(web_app_name:, password: 'ValidStr0ng!', **attrs)
    Account.create!(user: user, category: category, web_app_name: web_app_name, password: password, **attrs)
  end

  def create_event(event_type: 'account_created')
    ActivityEvent.create!(user: user, event_type: event_type)
  end

  describe '#call' do
    it 'returns all top-level keys' do
      result = described_class.new(user: user).call
      expect(result.keys).to match_array(%i[summary security reminders activity empty_state])
    end

    it 'shows onboarding when user has no accounts' do
      result = described_class.new(user: user).call
      expect(result[:empty_state][:show_onboarding]).to be(true)
    end

    it 'hides onboarding when user has accounts' do
      create_account(web_app_name: 'GitHub')
      result = described_class.new(user: user).call
      expect(result[:empty_state][:show_onboarding]).to be(false)
    end
  end

  describe 'summary' do
    it 'counts total accounts' do
      create_account(web_app_name: 'A')
      create_account(web_app_name: 'B')
      result = described_class.new(user: user).call
      expect(result[:summary][:total_accounts]).to eq(2)
    end

    it 'counts weak passwords' do
      create_account(web_app_name: 'A', password: 'short')
      create_account(web_app_name: 'B', password: 'ValidStr0ng!')
      result = described_class.new(user: user).call
      expect(result[:summary][:weak_password_count]).to eq(1)
    end
  end

  describe 'security score' do
    it 'returns 100 with no accounts' do
      result = described_class.new(user: user).call
      expect(result[:security][:score]).to eq(100)
    end

    it 'decreases score for weak passwords' do
      create_account(web_app_name: 'A', password: 'weak')
      result = described_class.new(user: user).call
      expect(result[:security][:score]).to be < 100
    end

    it 'never goes below 0' do
      15.times { |i| create_account(web_app_name: "Site#{i}", password: 'weak') }
      result = described_class.new(user: user).call
      expect(result[:security][:score]).to eq(0)
    end
  end

  describe 'reused_groups' do
    it 'groups accounts sharing a password and includes web_app_names' do
      create_account(web_app_name: 'SiteA', password: 'SharedPass1!')
      create_account(web_app_name: 'SiteB', password: 'SharedPass1!')
      result = described_class.new(user: user).call

      group = result[:security][:reused_groups].first
      expect(group[:web_app_names]).to match_array(%w[SiteA SiteB])
      expect(group[:account_ids].size).to eq(2)
      expect(group[:password_fingerprint]).to match(/\A[a-f0-9]{64}\z/)
    end

    it 'is empty when all passwords are unique' do
      create_account(web_app_name: 'A', password: 'Unique1Pass!')
      create_account(web_app_name: 'B', password: 'Unique2Pass!')
      result = described_class.new(user: user).call
      expect(result[:security][:reused_groups]).to be_empty
    end
  end

  describe 'activity pagination' do
    before { 20.times { create_event } }

    it 'returns DEFAULT_ACTIVITY_LIMIT events by default' do
      result = described_class.new(user: user).call
      expect(result[:activity][:events].size).to eq(described_class::DEFAULT_ACTIVITY_LIMIT)
    end

    it 'sets next_cursor when more events exist' do
      result = described_class.new(user: user).call
      expect(result[:activity][:next_cursor]).to be_a(String).and be_present
    end

    it 'returns nil next_cursor on the last page' do
      result = described_class.new(user: user, limit: 20).call
      expect(result[:activity][:next_cursor]).to be_nil
    end

    it 'pages through all events without overlap' do
      first  = described_class.new(user: user, limit: 10).call
      second = described_class.new(user: user, limit: 10, cursor: first[:activity][:next_cursor]).call

      first_ids  = first[:activity][:events].pluck(:id)
      second_ids = second[:activity][:events].pluck(:id)
      expect(first_ids & second_ids).to be_empty
      expect(first_ids.size + second_ids.size).to eq(20)
    end

    it 'falls back to first page when cursor is invalid' do
      baseline = described_class.new(user: user, limit: 10).call
      result   = described_class.new(user: user, limit: 10, cursor: '!!!invalid!!!').call

      expect(result[:activity][:events].pluck(:id))
        .to eq(baseline[:activity][:events].pluck(:id))
    end

    it 'clamps limit to MAX_ACTIVITY_LIMIT' do
      result = described_class.new(user: user, limit: 9999).call
      expect(result[:activity][:events].size).to be <= described_class::MAX_ACTIVITY_LIMIT
    end
  end
end

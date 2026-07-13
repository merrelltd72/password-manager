# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserSession do
  let(:user) { User.create!(username: 'sessuser', email: 'sess@example.com', password: 'Password1!') }

  let(:valid_attrs) do
    { user: user, jti: SecureRandom.uuid, expires_at: 30.minutes.from_now }
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(described_class.new(valid_attrs)).to be_valid
    end

    it 'requires jti' do
      session = described_class.new(valid_attrs.merge(jti: nil))
      expect(session).not_to be_valid
      expect(session.errors[:jti]).to be_present
    end

    it 'requires jti to be unique' do
      jti = SecureRandom.uuid
      described_class.create!(valid_attrs.merge(jti: jti))
      session = described_class.new(valid_attrs.merge(jti: jti))
      expect(session).not_to be_valid
    end

    it 'requires expires_at' do
      session = described_class.new(valid_attrs.merge(expires_at: nil))
      expect(session).not_to be_valid
      expect(session.errors[:expires_at]).to be_present
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe '#revoke!' do
    it 'sets revoked_at' do
      session = described_class.create!(valid_attrs)
      session.revoke!
      expect(session.reload.revoked_at).to be_present
    end
  end

  describe '#revoked?' do
    it 'returns false when revoked_at is nil' do
      expect(described_class.new(valid_attrs).revoked?).to be(false)
    end

    it 'returns true after revoke!' do
      session = described_class.create!(valid_attrs)
      session.revoke!
      expect(session.revoked?).to be(true)
    end
  end

  describe '#expired?' do
    it 'returns false when expires_at is in the future' do
      expect(described_class.new(valid_attrs.merge(expires_at: 1.minute.from_now)).expired?).to be(false)
    end

    it 'returns true when expires_at is in the past' do
      expect(described_class.new(valid_attrs.merge(expires_at: 1.minute.ago)).expired?).to be(true)
    end
  end

  describe '#active?' do
    it 'returns true for a fresh unrevoked session' do
      expect(described_class.new(valid_attrs).active?).to be(true)
    end

    it 'returns false when revoked' do
      session = described_class.create!(valid_attrs)
      session.revoke!
      expect(session.active?).to be(false)
    end

    it 'returns false when expired' do
      expect(described_class.new(valid_attrs.merge(expires_at: 1.minute.ago)).active?).to be(false)
    end
  end

  describe '.active scope' do
    it 'includes unrevoked unexpired sessions' do
      active = described_class.create!(valid_attrs)
      expect(described_class.active).to include(active)
    end

    it 'excludes revoked sessions' do
      session = described_class.create!(valid_attrs)
      session.revoke!
      expect(described_class.active).not_to include(session)
    end

    it 'excludes expired sessions' do
      session = described_class.create!(valid_attrs.merge(expires_at: 1.minute.ago))
      expect(described_class.active).not_to include(session)
    end
  end

  describe '.for_user scope' do
    it 'returns only sessions belonging to the given user' do
      other = User.create!(username: 'other', email: 'other@example.com', password: 'Password1!')
      own_session   = described_class.create!(valid_attrs)
      other_session = described_class.create!(user: other, jti: SecureRandom.uuid, expires_at: 30.minutes.from_now)

      expect(described_class.for_user(user)).to include(own_session)
      expect(described_class.for_user(user)).not_to include(other_session)
    end
  end
end

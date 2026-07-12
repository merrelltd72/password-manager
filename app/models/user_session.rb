# frozen_string_literal: true

class UserSession < ApplicationRecord
  belongs_to :user

  validates :jti, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where(revoked_at: nil).where('expires_at > ?', Time.current) }
  scope :for_user, ->(user) { where(user: user) }

  def revoke!
    update!(revoked_at: Time.current)
  end

  def revoked?
    revoked_at.present?
  end

  def expired?
    expires_at <= Time.current
  end

  def active?
    !revoked? && !expired?
  end
end

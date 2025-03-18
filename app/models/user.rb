# frozen_string_literal: true

class User < ApplicationRecord
  # User table one (user) to many (accounts) relationship with Accounts table.
  has_many :accounts

  # For username and password Authentication
  has_secure_password

  # Validations for username and password Authentication
  validates :email, presence: true, uniqueness: true
  validates :username, presence: true, uniqueness: true

  # Find or create a user based on OAuth data
  def self.find_or_create_from_auth_hash(auth_hash)
    where(provider: auth_hash.provider, uid: auth_hash.uid).first_or_create do |user|
      user.email = auth_hash.info.email
      user.username = auth_hash.info.name
      user.token = auth_hash.credentials.token
      user.provider = auth_hash.provider
    end
  end
end

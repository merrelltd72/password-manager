# frozen_string_literal: true

# User model representing an individual user of the application, including authentication and associations with accounts, reminders, and activity events.
class User < ApplicationRecord
  has_many :accounts
  has_many :password_reminders, dependent: :destroy
  has_many :activity_events, dependent: :destroy
  has_many :import_runs, dependent: :destroy
  has_many :export_runs, dependent: :destroy
  has_one :user_preference, dependent: :destroy

  # For username and password Authentication
  has_secure_password

  # Validations for username and password Authentication
  validates :email, presence: true, uniqueness: true
  validates :username, presence: true, uniqueness: true

  after_create :create_default_user_preference

  # Find or create a user based on OAuth data
  def self.find_or_create_from_auth_hash(auth_hash)
    where(provider: auth_hash.provider, uid: auth_hash.uid).first_or_create do |user|
      user.email = auth_hash.info.email
      user.username = auth_hash.info.name
      user.token = auth_hash.credentials.token
      user.provider = auth_hash.provider
    end
  end

  private

  def create_default_user_preference
    create_user_preference!(
      timezone: 'UTC',
      date_format: 'MMM d, yyyy',
      generator_defaults: generator_defaults,
      reminder_defaults: reminder_defaults
    )
  end

  def generator_defaults
    {
      length: 16,
      symbols: true,
      numbers: true,
      uppercase: true
    }
  end

  def reminder_defaults
    {
      lead_days: 7,
      repeat: 'none'
    }
  end
end

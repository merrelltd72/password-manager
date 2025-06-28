# frozen_string_literal: true

class PasswordReminder < ApplicationRecord
  belongs_to :account
  belongs_to :user

  validates :reminder_date, presence: true, future: true
  validates :notification_sent, inclusion: [true, false]

  before_create do
    self.notification_sent = false
  end
end

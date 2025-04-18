class PasswordReminder < ApplicationRecord
  belongs_to :account
  belongs_to :user

  validates :reminder_date, presence: true
  validates :notification_sent, inclusion: [true, false]

  before_create do
    self.notification_sent = false
  end

  private

  def reminder_date_must_be_in_the_future
    return unless reminder_date && reminder_date <= Time.current

    errors.add(:reminder_date, 'must be in the future!')
  end
end

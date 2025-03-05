# frozen_string_literal: true

class Reminder < ApplicationRecord
  belongs_to :task
  belongs_to :user

  validates :scheduled_at, presence: true
end

# frozen_string_literal: true

# Model representing user preferences, including timezone, date format, and default settings for password generation and reminders, allowing users to customize their experience within the application.
class UserPreference < ApplicationRecord
  belongs_to :user

  REPEAT_VALUES = %w[none weekly monthly quarterly].freeze

  validates :timezone, presence: true
  validates :date_format, presence: true

  validate :validate_timezone
  validate :validate_generator_defaults
  validate :validate_reminder_defaults

  private

  def validate_timezone
    return if ActiveSupport::TimeZone[timezone].present?

    errors.add(:timezone, 'is invalid')
  end

  def validate_generator_defaults
    value = generator_defaults || {}

    length = value['length'] || value[:length]
    symbols = value['symbols'].nil? ? value[:symbols] : value['symbols']
    numbers = value['numbers'].nil? ? value[:numbers] : value['numbers']
    uppercase = value['uppercase'].nil? ? value[:uppercase] : value['uppercase']

    unless length.is_a?(Integer) && length.between?(
      8, 64
    )
      errors.add(:generator_defaults,
                 'length must be an integer between 8 and 64')
    end
    errors.add(:generator_defaults, 'symbols must be boolean') unless [true, false].include?(symbols)
    errors.add(:generator_defaults, 'numbers must be boolean') unless [true, false].include?(numbers)
    errors.add(:generator_defaults, 'uppercase must be boolean') unless [true, false].include?(uppercase)
  end

  def validate_reminder_defaults
    value = reminder_defaults || {}

    lead_days = value['lead_days'] || value[:lead_days]
    repeat = value['repeat'] || value[:repeat]

    unless lead_days.is_a?(Integer) && lead_days.between?(
      0, 365
    )
      errors.add(:reminder_defaults,
                 'lead_days must be an integer between 0 and 365')
    end
    return if REPEAT_VALUES.include?(repeat)

    errors.add(:reminder_defaults,
               "repeat must be one of: #{REPEAT_VALUES.join(', ')}")
  end
end

# frozen_string_literal: true

# Methods for the Password Reminders controller
class PasswordRemindersController < ApplicationController
  def index
    @password_reminders = PasswordReminder.all
  end

  def create
    @password_reminder = PasswordReminder.new(password_reminder_params)
    if @password_reminder.save
      render json: @password_reminder, status: :created
    else
      render json: { error: 'Failed to create password reminder' }, status: :unprocessable_entity
    end
  end

  private

  def password_reminder_params
    params.require(:password_reminder).permit(:account_id, :user_id, :reminder_date)
  end
end

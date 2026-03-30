# frozen_string_literal: true

# Methods for the Password Reminders controller
class PasswordRemindersController < ApplicationController
  before_action :authenticate_user
  def index
    @password_reminders = current_user.password_reminders
  end

  def create
    @password_reminder = PasswordReminder.new(password_reminder_params)

    if @password_reminder.save
      PasswordReminders::Delivery.schedule(@password_reminder)

      render json: @password_reminder, status: :created
    else
      render json: { error: @password_reminder.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def password_reminder_params
    params.require(:password_reminder).permit(:account_id, :reminder_date).merge(user_id: current_user.id)
  end
end

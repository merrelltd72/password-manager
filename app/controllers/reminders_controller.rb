# frozen_string_literal: true

class RemindersController < ApplicationController
  def create
    @task = Task.find(params[:task_id])
    @reminder = @task.reminders.build(reminder_params)
    if @reminder.save
      PasswordReminderJob.perform_at(@current_user.id, @task.id, @reminder.scheduled_at)
      render json: @reminder, status: :created
    else
      render json: @reminder.errors, status: :unprocessable_entity
    end
  end

  private

  def reminder_params
    params.require(:reminder).permit(:scheduled_at)
  end
end

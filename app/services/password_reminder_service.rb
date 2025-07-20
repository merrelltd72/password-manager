class PasswordReminderService
  def initialize(account)
    @account = account
  end

  def create_reminder(params)
    @account.build_reminder(
      due_date: params[:due_date],
      frequency: params[:frequency]
    )
    @account.save!
  end

  def update_reminder(params)
    reminder = @account.reminder
    reminder.update!(
      due_date: params[:due_date],
      frequency: params[:frequency],
      notified: false
    )
  end

  def check_due_reminders
    reminders = Reminder.where(notified: false)

    reminders.each do |reminder|
      notify_user(reminder.account.user) if reminder.due_for_notifications?
    end
  end

  private

  def notify_user
    # need logic for this implementation
  end
end

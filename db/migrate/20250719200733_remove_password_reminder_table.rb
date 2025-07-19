class RemovePasswordReminderTable < ActiveRecord::Migration[8.0]
  def change
    drop_table :password_reminders
  end
end

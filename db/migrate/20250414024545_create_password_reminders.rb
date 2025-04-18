class CreatePasswordReminders < ActiveRecord::Migration[8.0]
  def change
    create_table :password_reminders do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :reminder_date
      t.boolean :notification_sent

      t.timestamps
    end
  end
end

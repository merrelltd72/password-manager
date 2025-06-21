# frozen_string_literal: true

# CreatePasswordReminders migration file
class CreatePasswordReminders < ActiveRecord::Migration[8.0]
  def change
    create_table :password_reminders do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.date :reminder_date
      t.boolean :notification_sent, default: false

      t.timestamps
    end
  end
end

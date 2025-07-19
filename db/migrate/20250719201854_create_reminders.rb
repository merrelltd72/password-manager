class CreateReminders < ActiveRecord::Migration[8.0]
  def change
    create_table :reminders do |t|
      t.date :due_date
      t.string :frequency
      t.boolean :notified
      t.datetime :last_notified_at

      t.timestamps
    end
  end
end

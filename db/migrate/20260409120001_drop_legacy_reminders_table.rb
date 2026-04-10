# frozen_string_literal: true

class DropLegacyRemindersTable < ActiveRecord::Migration[8.0]
  def change
    drop_table :reminders, if_exists: true
  end
end

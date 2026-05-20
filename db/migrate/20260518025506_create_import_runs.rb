# frozen_string_literal: true

# This migration creates the import_runs table to track the status and details of data import operations performed by users.
class CreateImportRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :import_runs do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.string :format, null: false
      t.string :source_filename
      t.integer :total_rows, null: false, default: 0
      t.integer :processed_rows, null: false, default: 0
      t.integer :succeeded_rows, null: false, default: 0
      t.integer :failed_rows, null: false, default: 0
      t.text :error_message
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :import_runs, %i[user_id created_at]
    add_index :import_runs, %i[user_id status]
  end
end

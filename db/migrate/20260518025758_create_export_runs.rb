# frozen_string_literal: true

# Migration to create the export_runs table, which tracks user-initiated data exports, their status, and related metadata.
class CreateExportRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :export_runs do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.string :format, null: false
      t.string :file_path
      t.string :download_token
      t.datetime :expires_at
      t.integer :record_count, null: false, default: 0
      t.text :error_message
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :export_runs, %i[user_id created_at]
    add_index :export_runs, %i[user_id status]
    add_index :export_runs, :download_token, unique: true
  end
end

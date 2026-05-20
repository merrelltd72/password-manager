# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 20_260_518_025_758) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'pg_catalog.plpgsql'

  create_table 'accounts', force: :cascade do |t|
    t.integer 'category_id'
    t.datetime 'created_at', null: false
    t.text 'notes'
    t.string 'password'
    t.datetime 'updated_at', null: false
    t.string 'url'
    t.bigint 'user_id', null: false
    t.string 'username'
    t.string 'web_app_name'
    t.index ['user_id'], name: 'index_accounts_on_user_id'
  end

  create_table 'activity_events', force: :cascade do |t|
    t.datetime 'created_at', null: false
    t.string 'event_type', null: false
    t.jsonb 'metadata', default: {}, null: false
    t.bigint 'subject_id'
    t.string 'subject_type'
    t.datetime 'updated_at', null: false
    t.bigint 'user_id', null: false
    t.index %w[subject_type subject_id], name: 'index_activity_events_on_subject_type_and_subject_id'
    t.index %w[user_id created_at], name: 'index_activity_events_on_user_id_and_created_at'
    t.index %w[user_id event_type created_at],
            name: 'index_activity_events_on_user_id_and_event_type_and_created_at'
    t.index ['user_id'], name: 'index_activity_events_on_user_id'
  end

  create_table 'categories', force: :cascade do |t|
    t.string 'category_type'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'export_runs', force: :cascade do |t|
    t.datetime 'completed_at'
    t.datetime 'created_at', null: false
    t.string 'download_token'
    t.text 'error_message'
    t.datetime 'expires_at'
    t.string 'file_path'
    t.string 'format', null: false
    t.integer 'record_count', default: 0, null: false
    t.datetime 'started_at'
    t.integer 'status', default: 0, null: false
    t.datetime 'updated_at', null: false
    t.bigint 'user_id', null: false
    t.index ['download_token'], name: 'index_export_runs_on_download_token', unique: true
    t.index %w[user_id created_at], name: 'index_export_runs_on_user_id_and_created_at'
    t.index %w[user_id status], name: 'index_export_runs_on_user_id_and_status'
    t.index ['user_id'], name: 'index_export_runs_on_user_id'
  end

  create_table 'import_runs', force: :cascade do |t|
    t.datetime 'completed_at'
    t.datetime 'created_at', null: false
    t.text 'error_message'
    t.integer 'failed_rows', default: 0, null: false
    t.string 'format', null: false
    t.integer 'processed_rows', default: 0, null: false
    t.string 'source_filename'
    t.datetime 'started_at'
    t.integer 'status', default: 0, null: false
    t.integer 'succeeded_rows', default: 0, null: false
    t.integer 'total_rows', default: 0, null: false
    t.datetime 'updated_at', null: false
    t.bigint 'user_id', null: false
    t.index %w[user_id created_at], name: 'index_import_runs_on_user_id_and_created_at'
    t.index %w[user_id status], name: 'index_import_runs_on_user_id_and_status'
    t.index ['user_id'], name: 'index_import_runs_on_user_id'
  end

  create_table 'password_reminders', force: :cascade do |t|
    t.bigint 'account_id', null: false
    t.datetime 'created_at', null: false
    t.boolean 'notification_sent', default: false
    t.date 'reminder_date'
    t.datetime 'updated_at', null: false
    t.bigint 'user_id', null: false
    t.index ['account_id'], name: 'index_password_reminders_on_account_id'
    t.index ['user_id'], name: 'index_password_reminders_on_user_id'
  end

  create_table 'tasks', force: :cascade do |t|
    t.datetime 'created_at', null: false
    t.text 'description'
    t.string 'title'
    t.datetime 'updated_at', null: false
    t.bigint 'user_id', null: false
    t.index ['user_id'], name: 'index_tasks_on_user_id'
  end

  create_table 'user_preferences', force: :cascade do |t|
    t.datetime 'created_at', null: false
    t.string 'date_format', default: 'MMM d, yyyy', null: false
    t.jsonb 'generator_defaults', default: {}, null: false
    t.jsonb 'reminder_defaults', default: {}, null: false
    t.string 'timezone', default: 'UTC', null: false
    t.datetime 'updated_at', null: false
    t.bigint 'user_id', null: false
    t.index ['user_id'], name: 'index_user_preferences_on_user_id', unique: true
  end

  create_table 'users', force: :cascade do |t|
    t.datetime 'created_at', null: false
    t.string 'email'
    t.string 'password_digest'
    t.string 'provider'
    t.string 'token'
    t.string 'uid'
    t.datetime 'updated_at', null: false
    t.string 'username'
    t.index %w[provider uid], name: 'index_users_on_provider_and_uid', unique: true
  end

  add_foreign_key 'accounts', 'users'
  add_foreign_key 'activity_events', 'users'
  add_foreign_key 'export_runs', 'users'
  add_foreign_key 'import_runs', 'users'
  add_foreign_key 'password_reminders', 'accounts'
  add_foreign_key 'password_reminders', 'users'
  add_foreign_key 'tasks', 'users'
  add_foreign_key 'user_preferences', 'users'
end

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

ActiveRecord::Schema[8.0].define(version: 20_250_614_173_604) do # rubocop:disable Metrics/BlockLength
  # These are extensions that must be enabled in order to support this database
  enable_extension 'pg_catalog.plpgsql'

  create_table 'accounts', force: :cascade do |t|
    t.string 'user_id'
    t.integer 'category_id'
    t.string 'web_app_name'
    t.string 'url'
    t.string 'username'
    t.string 'password'
    t.text 'notes'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'categories', force: :cascade do |t|
    t.string 'category_type'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'password_reminders', force: :cascade do |t|
    t.bigint 'account_id', null: false
    t.bigint 'user_id', null: false
    t.date 'reminder_date'
    t.boolean 'notification_sent', default: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['account_id'], name: 'index_password_reminders_on_account_id'
    t.index ['user_id'], name: 'index_password_reminders_on_user_id'
  end

  create_table 'tasks', force: :cascade do |t|
    t.string 'title'
    t.text 'description'
    t.bigint 'user_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['user_id'], name: 'index_tasks_on_user_id'
  end

  create_table 'users', force: :cascade do |t|
    t.string 'username'
    t.string 'email'
    t.string 'password_digest'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.string 'provider'
    t.string 'uid'
    t.string 'token'
    t.index %w[provider uid], name: 'index_users_on_provider_and_uid', unique: true
  end

  add_foreign_key 'password_reminders', 'accounts'
  add_foreign_key 'password_reminders', 'users'
  add_foreign_key 'tasks', 'users'
end

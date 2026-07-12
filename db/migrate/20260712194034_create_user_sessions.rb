# frozen_string_literal: true

class CreateUserSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :user_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string     :jti,        null: false
      t.string     :ip
      t.string     :user_agent
      t.datetime   :expires_at, null: false
      t.datetime   :revoked_at

      t.timestamps
    end

    add_index :user_sessions, :jti, unique: true
  end
end

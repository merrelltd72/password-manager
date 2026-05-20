# frozen_string_literal: true

class AddUserIdBigintToAccounts < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_column :accounts, :user_id_bigint, :bigint

    # Backfill only numeric legacy ids
    execute <<-SQL
      UPDATE accounts
      SET user_id_bigint = NULLIF(user_id, '')::bigint
      WHERE user_id ~ '^[0-9]+$'
    SQL

    # Add an index on the new bigint column for better performance
    add_index :accounts, :user_id_bigint, algorithm: :concurrently
    add_foreign_key :accounts, :users, column: :user_id_bigint

    # Fail fast if bad legacy data is found
    invalid_count = select_value(<<~SQL).to_i
      SELECT COUNT(*)
      FROM accounts
      WHERE user_id IS NOT NULL AND user_id <> '' AND user_id !~ '^[0-9]+$'
    SQL

    raise "Non-numeric accounts.user_id found: #{invalid_count} records" if invalid_count.positive?

    change_column_null :accounts, :user_id_bigint, false
  end

  def down
    remove_foreign_key :accounts, column: :user_id_bigint
    remove_index :accounts, :user_id_bigint
    remove_column :accounts, :user_id_bigint
  end
end

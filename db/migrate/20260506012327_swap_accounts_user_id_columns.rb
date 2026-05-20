# frozen_string_literal: true

class SwapAccountsUserIdColumns < ActiveRecord::Migration[8.1]
  def up
    remove_column :accounts, :user_id
    rename_column :accounts, :user_id_bigint, :user_id
  end

  def down
    add_column :accounts, user_id, :string
    execute <<~SQL
      UPDATE accounts
      SET user_id = user_id::text
    SQL
    rename_column :accounts, :user_id, :user_id_bigint
  end
end

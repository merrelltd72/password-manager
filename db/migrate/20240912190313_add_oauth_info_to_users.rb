# frozen_string_literal: true

class AddOauthInfoToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_column :users, :token, :string
    add_index :users, %i[provider uid], unique: true
  end
end

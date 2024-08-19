class CreateAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :accounts do |t|
      t.string :user_id
      t.integer :category_id
      t.string :web_app_name
      t.string :url
      t.string :username
      t.string :password
      t.text :notes

      t.timestamps
    end
  end
end

class CreateUserPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :user_preferences do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :timezone, null: false, default: 'UTC'
      t.string :date_format, null: false, default: 'MMM d, yyyy'
      t.jsonb :generator_defaults, null: false, default: {}
      t.jsonb :reminder_defaults, null: false, default: {}

      t.timestamps
    end
  end
end

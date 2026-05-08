class CreateActivityEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_events do |t|
      t.references :user, null: false, foreign_key: true
      t.string :event_type, null: false
      t.string :subject_type
      t.bigint :subject_id
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :activity_events, %i[user_id created_at]
    add_index :activity_events, %i[user_id event_type created_at]
    add_index :activity_events, %i[subject_type subject_id]
  end
end

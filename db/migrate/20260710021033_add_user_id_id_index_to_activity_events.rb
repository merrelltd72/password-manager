# frozen_string_literal: true

class AddUserIdIdIndexToActivityEvents < ActiveRecord::Migration[8.1]
  def change
    add_index :activity_events, %i[user_id id],
              order: { id: :desc },
              name: 'index_activity_events_on_user_id_and_id_desc'
  end
end

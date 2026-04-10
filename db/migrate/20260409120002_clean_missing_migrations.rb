# frozen_string_literal: true

class CleanMissingMigrations < ActiveRecord::Migration[8.0]
  def up
    # Remove orphaned migration records that have no corresponding migration file
    # These occurred due to schema drift or deleted migration files
    missing_versions = %w[
      20250305021957
      20250305022142
      20250414024545
      20250719200733
      20250719201854
    ]

    missing_versions.each do |version|
      execute("DELETE FROM schema_migrations WHERE version = '#{version}'")
    end
  end

  def down
    # No-op: we don't want to re-insert orphaned migration records
  end
end

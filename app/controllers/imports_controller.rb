# frozen_string_literal: true

# Controller for handling account data imports, providing an interface to view and manage import operations initiated by users.
class ImportsController < ApplicationController
  DEFAULT_LIMIT = 20
  MAX_LIMIT = 100

  before_action :authenticate_user

  def index
    runs = current_user.import_runs.recent_first.limit(normalized_limit)
    render json: { imports: runs.map { |run| serialize_import(run) } }, status: :ok
  end

  private

  def normalized_limit
    value = params[:limit].to_i
    return DEFAULT_LIMIT if value <= 0

    [value, MAX_LIMIT].min
  end

  def serialize_import(run)
    {
      id: run.id,
      status: run.status,
      format: run.format,
      source_filename: run.source_filename,
      total_rows: run.total_rows,
      processed_rows: run.processed_rows,
      succeeded_rows: run.succeeded_rows,
      failed_rows: run.failed_rows,
      error_message: run.error_message,
      started_at: run.started_at&.iso8601,
      completed_at: run.completed_at&.iso8601,
      created_at: run.created_at.iso8601
    }
  end
end

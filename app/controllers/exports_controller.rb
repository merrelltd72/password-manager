# frozen_string_literal: true

# Controller handling user-initiated export operations for account data, allowing users to request exports in various formats and track their status for download.
class ExportsController < ApplicationController
  before_action :authenticate_user
  before_action :set_export_run, only: :show

  def create
    format = export_params[:format].presence || 'csv'
    run = current_user.export_runs.create!(format: format)

    # Future implementation: Exports::GenerateFileJob.perform_later(run.id)
    render json: serialize_export(run), status: :accepted
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  def show
    render json: serialize_export(@export_run), status: :ok
  end

  private

  def export_params
    params.permit(:format)
  end

  def set_export_run
    @export_run = current_user.export_runs.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Export not found' }, status: :not_found
  end

  def serialize_export(run)
    {
      id: run.id,
      status: run.status,
      format: run.format,
      error_message: run.error_message,
      record_count: run.record_count,
      expires_at: run.expires_at&.iso8601,
      download_url: download_url_for(run),
      created_at: run.created_at.iso8601,
      started_at: run.started_at&.iso8601,
      completed_at: run.completed_at&.iso8601
    }
  end

  def download_url_for(run)
    return nil unless run.completed?
    return nil if run.mark_failed!

    run.file_path
  end
end

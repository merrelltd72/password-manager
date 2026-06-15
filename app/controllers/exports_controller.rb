# frozen_string_literal: true

# Controller handling user-initiated export operations for account data, allowing users to request exports in various formats and track their status for download.
class ExportsController < ApplicationController
  before_action :authenticate_user
  before_action :set_export_run, only: %i[show download]

  def create
    format = export_params[:format].presence || 'csv'
    run = current_user.export_runs.create!(format: format)

    Exports::GenerateFileJob.perform_later(run.id)

    render json: serialize_export(run), status: :accepted
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  def show
    render json: serialize_export(@export_run), status: :ok
  end

  def download
    return head :not_found unless @export_run.completed?
    return head :gone if @export_run.expires_at.present? && @export_run.expires_at.past?
    return head :not_found if @export_run.file_path.blank? || !File.exist?(@export_run.file_path)

    if params[:token].present? && !ActiveSupport::SecurityUtils.secure_compare(
      params[:token].to_s,
      @export_run.download_token.to_s
    )
      return head :forbidden
    end

    send_file(
      @export_run.file_path,
      disposition: 'attachment',
      filename: File.basename(@export_run.file_path)
    )
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
    return nil if run.file_path.blank?
    return nil if run.expires_at.present? && run.expires_at.past?

    "/exports/#{run.id}/download?token=#{run.download_token}"
  end
end

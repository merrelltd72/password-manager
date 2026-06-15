# frozen_string_literal: true

module Exports
  class GenerateFileJob < ApplicationJob
    queue_as :default

    retry_on StandardError, wait: :exponentially_longer, attempts: 3

    def perform(export_run_id)
      run = ExportRun.find(export_run_id)
      return unless run.pending? || run.failed?

      run.mark_processing!

      generated = Exports::FileBuilder.call(run: run)

      run_mark_completed(run, generated)
    rescue ActiveRecord::RecordNotFound
      nil
    rescue StandardError => e
      run&.mark_failed!(e.message)
      raise
    end

    def run_mark_completed(run, generated)
      run.mark_completed!(
        path: generated[:path],
        expires_at: generated[:expires_at],
        record_count: generated[:record_count]
      )
    end
  end
end

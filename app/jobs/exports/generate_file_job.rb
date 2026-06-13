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
      # generated => { path:, record_count:, expires_at: }

      run.mark_completed!(
        path: generated[:path],
        expires_at: generated[:expires_at],
        record_count: generated[:record_count]
      )
    rescue ActiveRecord::RecordNotFound
      run.delete
    rescue StandardError => e
      run&.mark_failed!(e.message)
      raise
    end
  end
end

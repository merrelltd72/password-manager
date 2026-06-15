# frozen_string_literal: true

module Exports
  class CleanupExpiredJob < ApplicationJob
    queue_as :default

    def perform
      ExportRun.completed.where('expires_at < ?', Time.current).find_each do |run|
        File.delete(run.file_path) if run.file_path.present? && File.exist?(run.file_path)
        run.update!(file_path: nil)
      end
    end
  end
end

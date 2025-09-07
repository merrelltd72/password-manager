# frozen_string_literal: true

every 5.minute do
  runner 'ReminderCheckerWorker.perform_async'
end

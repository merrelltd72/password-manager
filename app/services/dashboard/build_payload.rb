# frozen_string_literal: true

module Dashboard
  class BuildPayload
    DUE_SOON_DAYS = 7
    ACTIVITY_LIMIT = 15

    def initialize(user:, due_soon_days: DUE_SOON_DAYS, activity_limit: ACTIVITY_LIMIT)
      @user = user
      @due_soon_days = due_soon_days
      @activity_limit = activity_limit
    end

    def call
      accounts = @user.accounts.to_a
      reminders = @user.password_reminders.includes(:account).to_a
      events = @user.activity_events.recent_first.limit(@activity_limit).to_a

      weak_accounts = accounts.select { |a| weak_password?(a.password.to_s) }
      reused_groups = build_reused_groups(accounts)
      due_today, due_soon = split_reminders(reminders)

      {
        summary: {
          total_accounts: accounts.size,
          weak_password_count: weak_accounts.size,
          reused_password_count: reused_groups.sum { |g| g[:account_ids].size },
          reminders_due_soon_count: due_soon.size + due_today.size,
          last_sync_at: [accounts.map(&:updated_at).max, reminders.map(&:updated_at).max,
                         events.map(&:created_at).max].compact.max&.iso8601
        },
        security: {
          score: security_score(accounts_count: accounts.size, weak_count: weak_accounts.size,
                                reused_count: reused_groups.size),
          weak_accounts: weak_accounts.map { |a| { id: a.id, web_app_name: a.web_app_name } },
          reused_groups: reused_groups
        },
        reminders: {
          due_today: due_today.map { |r| reminder_json(r) },
          due_soon: due_soon.map { |r| reminder_json(r) }
        },
        activity: {
          events: events.map { |e| event_json(e) },
          next_cursor: nil
        },
        empty_state: {
          show_onboarding: accounts.empty?
        }
      }
    end

    private

    def weak_password?(password)
      return true if password.length < 12
      return true unless password.match?(/[a-z]/)
      return true unless password.match?(/[A-Z]/)
      return true unless password.match?(/[0-9]/)
      return true unless password.match?(/[^A-Za-z0-9]/)

      false
    end

    def build_reused_groups(accounts)
      grouped = accounts.group_by { |account| account.password.to_s }
      reused = grouped.select { |password, group| password.present? && group.size > 1 }

      reused.map do |password, group|
        {
          password_fingerprint: Digest::SHA256.hexdigest(password),
          account_ids: group.map(&:id),
          web_app_names: group.map(&:web_app_name)
        }
      end
    end

    def split_reminders(reminders)
      today = Date.current
      soon_cutoff = today + @due_soon_days.days

      due_today = reminders.select { |reminder| reminder.reminder_date == today && !reminder.notification_sent }
      due_soon = reminders.select do |reminder|
        !reminder.notification_sent && reminder.reminder_date.present? && reminder.reminder_date > today && reminder.reminder_date <= soon_cutoff
      end
      [due_today, due_soon]
    end

    def reminder_json(reminder)
      {
        id: reminder.id,
        account_id: reminder.account_id,
        account_name: reminder.account.web_app_name,
        reminder_date: reminder.reminder_date
      }
    end

    def event_json(event)
      {
        id: event.id,
        event_type: event.event_type,
        subject_type: event.subject_type,
        subject_id: event.subject_id,
        metadata: event.metadata,
        created_at: event.created_at.iso8601
      }
    end

    def security_score(accounts_count:, weak_count:, reused_count:)
      return 100 if accounts_count.zero?

      deduction = (weak_count * 8) + (reused_count * 10)
      [100 - deduction, 0].max
    end
  end
end

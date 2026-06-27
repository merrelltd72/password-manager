# frozen_string_literal: true

module Dashboard
  class BuildPayload
    DUE_SOON_DAYS = 7
    DEFAULT_ACTIVITY_LIMIT = 15
    MAX_ACTIVITY_LIMIT = 50

    def initialize(user:, due_soon_days: DUE_SOON_DAYS, cursor: nil, limit: nil)
      @user = user
      @due_soon_days = due_soon_days
      @cursor = cursor
      @limit = clamp_limit(limit)
    end

    def call
      accounts = @user.accounts.to_a
      reminders = @user.password_reminders.includes(:account).to_a
      events, next_cursor = fetch_activity_page

      weak_accounts = accounts.select { |a| weak_password?(a.password.to_s) }
      reused_groups = build_reused_groups(accounts)
      due_today, due_soon = split_reminders(reminders)

      {
        summary: {
          total_accounts: accounts.size,
          weak_password_count: weak_accounts.size,
          reused_password_count: reused_groups.sum { |g| g[:account_ids].size },
          reminders_due_soon_count: due_soon.size + due_today.size,
          last_sync_at: compute_last_sync_at(accounts, reminders)
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
          next_cursor: next_cursor
        },
        empty_state: {
          show_onboarding: accounts.empty?
        }
      }
    end

    private

    def clamp_limit(limit)
      return DEFAULT_ACTIVITY_LIMIT if limit.blank?

      [[limit.to_i, 1].max, MAX_ACTIVITY_LIMIT].min
    end

    def fetch_activity_page
      scope = @user.activity_events.order(id: :desc)
      scope = scope.where('id < ?', decode_cursor(@cursor)) if @cursor.present?

      rows = scope.limit(@limit + 1).to_a
      has_more = rows.size > @limit
      events = has_more ? rows.first(@limit) : rows
      next_cursor = has_more ? encode_cursor(events.last.id) : nil

      [events, next_cursor]
    end

    def compute_last_sync_at(accounts, reminders)
      [
        accounts.map(&:updated_at).max,
        reminders.map(&:updated_at).max,
        @user.activity_events.maximum(:created_at)
      ].compact.max&.iso8601
    end

    def encode_cursor(id)
      Base64.strict_encode64(id.to_s)
    end

    def decode_cursor(token)
      Base64.strict_decode64(token).to_i
    rescue ArgumentError
      nil
    end

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

      due_today = reminders.select { |r| r.reminder_date == today && !r.notification_sent }
      due_soon = reminders.select do |r|
        !r.notification_sent && r.reminder_date.present? &&
          r.reminder_date > today && r.reminder_date <= soon_cutoff
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

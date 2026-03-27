# Password Reminder Websocket Flow

```mermaid
sequenceDiagram
    autonumber
    participant Browser as Frontend Browser
    participant Cable as Action Cable
    participant Channel as PasswordRemindersChannel
    participant Controller as PasswordRemindersController
    participant Model as PasswordReminder
    participant Delivery as PasswordReminders::Delivery
    participant Job as PasswordReminderJob
    participant Worker as PasswordReminderWorker

    Browser->>Cable: Connect to /cable with signed jwt cookie
    Cable->>Cable: Resolve current_user from cookie
    Browser->>Channel: Subscribe to PasswordRemindersChannel
    Channel->>Channel: stream_for current_user

    rect rgb(235, 245, 255)
        Note over Browser,Job: HTTP creation path
        Browser->>Controller: POST /reminders
        Controller->>Controller: authenticate_user
        Controller->>Model: create reminder for current_user
        Model-->>Controller: reminder persisted
        Controller->>Delivery: schedule(reminder)
        Delivery->>Job: perform_at(noon, reminder.id)
        Controller-->>Browser: 201 Created
    end

    rect rgb(237, 255, 240)
        Note over Browser,Job: Websocket creation path
        Browser->>Channel: perform("create", { account_id, reminder_date })
        Channel->>Model: create reminder for current_user
        Model-->>Channel: reminder persisted
        Channel->>Delivery: schedule(reminder)
        Delivery->>Job: perform_at(noon, reminder.id)
        Channel->>Delivery: broadcast(reminder)
        Delivery->>Channel: broadcast_to(current_user, payload)
        Channel-->>Browser: received({ reminder })
    end

    rect rgb(255, 246, 235)
        Note over Job,Browser: Scheduled delivery path
        Job->>Model: find(reminder_id)
        Job->>Job: skip if sent or not due
        Job->>Delivery: broadcast(reminder)
        Delivery->>Channel: broadcast_to(reminder.user, payload)
        Channel-->>Browser: received({ reminder })
        Job->>Model: mark notification_sent = true
    end

    rect rgb(252, 241, 255)
        Note over Worker,Browser: Catch-up sweep path
        Worker->>Model: due_reminders.find_each
        loop each due reminder
            Worker->>Delivery: broadcast(reminder)
            Delivery->>Channel: broadcast_to(reminder.user, payload)
            Channel-->>Browser: received({ reminder })
            Worker->>Model: mark_notified!
        end
    end
```

## Notes

- Both HTTP and websocket reminder creation now use the same scheduling service.
- All outbound websocket payloads flow through `PasswordReminders::Delivery.broadcast`.
- Delivery is user-scoped because the channel subscribes with `stream_for current_user`.
- The websocket create path gives an immediate echo of the newly created reminder and also schedules future delivery.

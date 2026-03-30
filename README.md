# Password Manager

Welcome to the Password Management Application! This tool will help you securely manage and store your passwords with complete control over its deployment and management. The application has a React frontend and Ruby on Rails backend. Currently it is under construction.

## Features

- **Secure Password Storage:** Encrypts passwords using advanced algorithms.
- **User Management:** Supports multiple user accounts with different access levels.
- **Realtime Password Reminder Notifications:** Delivers user-scoped reminder updates over Action Cable.

## Planned Features

- **Customizable Deployment:** Allows users to deploy on various environments (local, server, cloud).

- **Backup & Recovery:** Provides options for data backup and recovery.
- **Multi-Factor Authentication:** Enhances security with additional authentication layers.
- **Import/Export Passwords:** Easily import and export password data for convenient management.

## Technology Stack

- **Backend:** Ruby on Rails
- **Database:** PostgreSQL
- **Authentication:** JWT
- **Background Jobs:** Sidekiq
- **Websockets:** Action Cable

## What Was Added

The reminder system now supports end-to-end websocket delivery with shared scheduling and broadcast logic.

- Added a shared reminder delivery service at [app/services/password_reminders/delivery.rb](app/services/password_reminders/delivery.rb).
- Unified scheduling logic so both HTTP and websocket reminder creation use the same flow.
- Unified websocket payload broadcasting through one service method.
- Updated websocket channel to use user-scoped streams and secure account ownership checks.
- Added reminder scheduling from websocket-created reminders.
- Added a documented flow diagram at [docs/password-reminder-websocket-flow.md](docs/password-reminder-websocket-flow.md).

### Reminder Flow Overview

1. Client connects to `/cable` using signed JWT cookie authentication.
2. Client subscribes to `PasswordRemindersChannel`.
3. Reminder is created via HTTP (`POST /reminders`) or channel action (`create`).
4. Reminder scheduling is handled by `PasswordReminders::Delivery.schedule`.
5. Scheduled delivery runs through `PasswordReminderJob`.
6. Catch-up delivery runs through `PasswordReminderWorker` using `due_reminders`.
7. Websocket messages are broadcast with user scoping through `PasswordReminders::Delivery.broadcast`.

## Getting Started

### Prerequisites

- Ruby 3.4.4+
- Rails 8.1.0+
- PostgreSQL 14.13+

### Quick Start

1. Clone the repository:
   ```
   git@github.com:merrelltd72/password-manager.git
   ```
2. Install dependencies:
   ```
   bundle install
   ```
3. Setup the database:
   ```
   rails db:create db:migrate db:seed
   ```
4. Start the server:
   ```
   rails server
   ```
5. Start Sidekiq for reminder job processing:
   ```
   bundle exec sidekiq
   ```

### Running Tests

- Run the full suite:
  ```
  bundle exec rspec
  ```
- Run reminder-focused specs only:
  ```
  bundle exec rspec spec/models/password_reminder_spec.rb spec/requests/password_reminders_spec.rb spec/channels/password_reminders_channel_spec.rb spec/jobs/password_reminder_job_spec.rb spec/workers/password_reminder_worker_spec.rb spec/services/password_reminders/delivery_spec.rb
  ```

The frontend for this application can be found here -> https://github.com/merrelltd72/password-manager-frontend

_This project was developed as part of my journey to become a professional software developer. It showcases my ability to design and implement complex systems, work with databases, and create user-friendly APIs._

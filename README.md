# Password Manager

Welcome to the Password Management Application! This tool will help you securely manage and store your passwords with complete control over its deployment and management. The application has a React frontend and Ruby on Rails backend. Currently it is under construction.

## Features

- **Secure Password Storage:** Encrypts passwords using advanced algorithms.
- **User Management:** Supports multiple user accounts with different access levels.

## Planned Features

- **Customizable Deployment:** Allows users to deploy on various environments (local, server, cloud).

- **Backup & Recovery:** Provides options for data backup and recovery.
- **Multi-Factor Authentication:** Enhances security with additional authentication layers.
- **Import/Export Passwords:** Easily import and export password data for convenient management.

## Technology Stack

- **Backend:** Ruby on Rails
- **Database:** PostgreSQL
- **Authentication:** JWT

## Getting Started

### Prerequisites

- Ruby 3.3.1+
- Rails 7.1.3+
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

The frontend for this application can be found here -> https://github.com/merrelltd72/password-manager-frontend

_This project was developed as part of my journey to become a professional software developer. It showcases my ability to design and implement complex systems, work with databases, and create user-friendly APIs._

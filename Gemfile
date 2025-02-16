source "https://rubygems.org"

ruby "3.3.1"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "8.0.0"

# Shim to load environment variables from .env into ENV in development. https://github.com/bkeepers/dotenv
gem 'dotenv', groups: [:development, :test, :production]

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.5.9"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Redis adapter to run Action Cable in production
# gem "redis", ">= 4.0.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

gem "jwt"

gem "rack-cors"

gem "sidekiq"

# A Scope & Engine based, clean, powerful, customizable and sophisticated paginator for modern web app frameworks and ORMs https://github.com/kaminari/kaminari
gem 'kaminari'

# Roo implements read access for all common spreadsheet types. https://github.com/roo-rb/roo
gem "roo", "~> 2.10", ">= 2.10.1"

# The CSV library provides a complete interface to CSV files and data. https://rubygems.org/gems/csv
gem "csv", "~> 3.3.2"

# OmniAuth is a library that standardizes multi-provider authentication for web applications. https://github.com/omniauth/omniauth
gem 'omniauth'

# Strategy to authenticate with Google via OAuth2 in OmniAuth. https://github.com/zquestz/omniauth-google-oauth2
gem 'omniauth-google-oauth2'

# https://github.com/mislav/will_paginate?tab=readme-ov-file
 gem 'will_paginate', '~> 4.0'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ]
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end

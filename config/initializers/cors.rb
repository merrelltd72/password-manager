# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:5173'
    resource '*',
             headers: :any,
             credentials: true,
             methods: %i[get post patch put delete options head],
             expose: ['X-CSRF-Token']
  end
end

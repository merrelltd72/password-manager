# frozen_string_literal: true

module ApplicationCable
  # Connection Setup
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    protected

    def find_verified_user
      verified_user = AuthenticationHelper.current_user
      return verified_user if verified_user&.authenticated?

      reject_unauthorized_connection
    end
  end
end

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
      verified_user = User.find_by(session_token: cookies.signed[:session_token])
      return verified_user if verified_user

      reject_unauthorized_connection
    end
  end
end

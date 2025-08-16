# frozen_string_literal: true

module ApplicationCable
  # Connection Setup
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      logger.add_tags current_user: current_user.id
    end

    private

    def find_verified_user
      user = find_user_from_session
      user || reject_unauthorized_connection
    end

    def find_user_from_session
      decoded_token = generate_token
      User.find_by(id: decoded_token[0]['user_id'])
    end

    def generate_token
      token = cookies.signed[:jwt]
      JWT.decode(
        token,
        Rails.application.credentials.fetch(:secret_key_base),
        true,
        { algorithm: 'HS256' }
      )
    end
  end
end

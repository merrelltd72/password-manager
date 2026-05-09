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
      token = cookies.signed[:jwt]
      reject_unauthorized_connection unless token

      decoded = JWT.decode(
        token,
        jwt_secret_key,
        true,
        { algorithm: 'HS256' }
      )

      user_id = decoded[0]['user_id']
      verified_user = User.find_by(id: user_id)
      return verified_user if verified_user

      reject_unauthorized_connection
    rescue JWT::DecodeError, JWT::ExpiredSignature, KeyError
      reject_unauthorized_connection
    end

    def jwt_secret_key
      Rails.application.credentials.secret_key_base.presence ||
        ENV['SECRET_KEY_BASE'].presence ||
        Rails.application.secret_key_base
    end
  end
end

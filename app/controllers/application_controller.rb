# frozen_string_literal: true

# Configuration for ActionController
class ApplicationController < ActionController::Base
  # protect_from_forgery with: :exception, unless: -> { request.format.json? }
  protect_from_forgery with: :exception, unless: -> { request.format.json? }

  def current_user
    token = cookies.signed[:jwt]
    return unless token

    begin
      decoded_token = generate_jwt_token(token)
      User.find_by(id: decoded_token[0]['user_id'])
    rescue JWT::ExpiredSignature
      nil
    end
  end

  def authenticate_user
    return if current_user

    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

  private

  def generate_jwt_token(token)
    JWT.decode(
      token,
      jwt_secret_key,
      true,
      { algorithm: 'HS256' }
    )
  end

  def jwt_secret_key
    Rails.application.credentials.secret_key_base.presence ||
      ENV['SECRET_KEY_BASE'].presence ||
      Rails.application.secret_key_base
  end
end
